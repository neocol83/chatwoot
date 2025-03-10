<script>
/* eslint no-console: 0 */
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../components/Modal.vue';

export default {
  components: {
    WootSubmitButton,
    Modal,
    WootMessageEditor,
  },
  props: {
    id: { type: Number, default: null },
    edcontent: { type: String, default: '' },
    edshortCode: { type: String, default: '' },
    edFilePath: { type: String, default: null },
    onClose: { type: Function, default: () => {} },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      editCanned: {
        showAlert: false,
        showLoading: false,
      },
      shortCode: this.edshortCode,
      content: this.edcontent,
      currentFilePath: this.edFilePath,
      newFile: null,
      deleteExistingFile: false,
      show: true,
    };
  },
  validations: {
    shortCode: {
      required,
      minLength: minLength(2),
    },
    content: {
      required,
    },
  },
  computed: {
    pageTitle() {
      return `${this.$t('CANNED_MGMT.EDIT.TITLE')} - ${this.edshortCode}`;
    },
  },
  methods: {
    setPageName({ name }) {
      this.v$.content.$touch();
      this.content = name;
    },
    resetForm() {
      this.shortCode = '';
      this.content = '';
      this.v$.shortCode.$reset();
      this.v$.content.$reset();
    },
    editCannedResponse() {
      // Show loading on button
      this.editCanned.showLoading = true;
      // Make API Calls
      const formData = new FormData();
      formData.append('canned_response[short_code]', this.shortCode);
      formData.append('canned_response[content]', this.content);
      if (this.newFile) {
        formData.append('canned_response[canned_file]', this.newFile);
      }
      formData.append('canned_response[delete_canned_file]', this.deleteExistingFile);
      this.$store.dispatch('updateCannedResponse', { id: this.id, updateObj: formData })
        .then(() => {
          // Reset Form, Show success message
          this.editCanned.showLoading = false;
          useAlert(this.$t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE'));
          this.resetForm();
          setTimeout(() => {
            this.onClose();
          }, 10);
        })
        .catch(error => {
          this.editCanned.showLoading = false;
          const errorMessage =
            error?.message || this.$t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE');
          useAlert(errorMessage);
        });
    },
    onFileChange(event) {
      this.newFile = event.target.files[0];
      this.deleteExistingFile = true;
    },
    removeAttachedFile() {
      this.currentFilePath = null;
      this.newFile = null;
      this.deleteExistingFile = true;
      useAlert(this.$t('CANNED_MGMT.EDIT.FORM.ATTACHED_FILE.REMOVED_MESSAGE'));
    },
    getFileNameFromPath(filePath) {
      return filePath ? filePath.split('/').pop() : '';
    },
  },
};
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="pageTitle" />
      <form class="flex flex-col w-full" @submit.prevent="editCannedResponse()">
        <div class="w-full">
          <label :class="{ error: v$.shortCode.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model.trim="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.PLACEHOLDER')"
              @input="v$.shortCode.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.content.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.CONTENT.LABEL') }}
          </label>
          <div class="editor-wrap">
            <WootMessageEditor
                v-model="content"
                class="message-editor [&>div]:px-1"
                :class="{ editor_warning: v$.content.$error }"
                enable-variables
                :enable-canned-responses="false"
                :placeholder="$t('CANNED_MGMT.EDIT.FORM.CONTENT.PLACEHOLDER')"
                @blur="v$.content.$touch"
              />
          </div>
        </div>

        <div v-if="currentFilePath" class="w-full mt-4">
          <p>{{ $t('CANNED_MGMT.EDIT.FORM.ATTACHED_FILE.LABEL') }}</p>
          <div class="flex items-center justify-between border rounded-md" style="padding-left: 8px; padding-right: 8px;">
            <span>{{ getFileNameFromPath(currentFilePath) }}</span>
            <button class="button clear secondary" @click.prevent="removeAttachedFile">
              {{ $t('CANNED_MGMT.EDIT.FORM.ATTACHED_FILE.REMOVE_BUTTON') }}
            </button>
          </div>
        </div>

        <div class="w-full mt-4">
          <label>{{ $t('CANNED_MGMT.EDIT.FORM.UPLOAD_NEW_FILE.LABEL') }}</label>
          <input type="file" @change="onFileChange" />
        </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <WootSubmitButton
          :disabled="
              v$.content.$invalid ||
              v$.shortCode.$invalid ||
              editCanned.showLoading
            "
            :button-text="$t('CANNED_MGMT.EDIT.FORM.SUBMIT')"
            :loading="editCanned.showLoading"
          />
          <button class="button clear" @click.prevent="onClose">
            {{ $t('CANNED_MGMT.EDIT.CANCEL_BUTTON_TEXT') }}
          </button>
        </div>
      </form>
    </div>
  </Modal>
</template>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar {
    @apply hidden;
  }

  .ProseMirror-woot-style {
    @apply min-h-[12.5rem];

    p {
      @apply text-base;
    }
  }
}
</style>
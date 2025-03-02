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
    edFilePath: { type: String, default: null }, // <= NEW: Prop for edFilePath
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
      show: true,
      currentFilePath: this.edFilePath, // <= INITIALIZE from prop
      newFile: null,         // <= Para almacenar el nuevo archivo seleccionado
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
      this.newFile = null; // Limpiar el archivo seleccionado al resetear el formulario
      this.currentFilePath = null; // Limpiar la ruta del archivo
      this.v$.shortCode.$reset();
      this.v$.content.$reset();
    },
    editCannedResponse() {
      this.editCanned.showLoading = true;
      this.v$.$validate()
          .then(isFormValid => {
              if (!isFormValid) {
                  this.editCanned.showLoading = false;
                  return;
              }

              console.log('editCannedResponse - this.newFile al inicio:', this.newFile);

              const formData = new FormData();
              formData.append('canned_response[short_code]', this.shortCode);
              formData.append('canned_response[content]', this.content);
              if (this.newFile) {
                  formData.append('canned_response[canned_file]', this.newFile, this.newFile.name, { contentType: 'image/png' }); // For PNG
              }

              console.log('Contenido de FormData en EditCanned.vue:');
              for (const pair of formData.entries()) {
                  console.log(pair[0] + ', ' + pair[1]);
              }

              const dispatchPayload = {
                  id: this.id,
                  updateObj: formData,
              };

              console.log('Dispatch Payload in EditCanned.vue:', dispatchPayload);

              this.$store
                  .dispatch('updateCannedResponse', dispatchPayload /* <= REMOVED headers option! */)
                  .then(() => {
                      this.editCanned.showLoading = false; // <= ADDED success handling: stop loading
                      useAlert(this.$t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE')); // <= Optional success alert
                      this.resetForm(); // <= Keep existing form reset logic
                      setTimeout(() => {
                          this.onClose();
                      }, 10); // <= Keep existing timeout logic
                      // Potentially: Refresh canned response list or update UI here
                  })
                  .catch(error => {
                      this.editCanned.showLoading = false;
                      const errorMessage =
                          error?.message || this.$t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE');
                      useAlert(errorMessage);
                      console.error("File Upload/Update Error:", error);
                  });
          });
    },
    getFileNameFromPath(filePath) {
      if (!filePath) return '';
      const parts = filePath.split('/');
      return parts[parts.length - 1];
    },
    removeAttachedFile() {
      this.currentFilePath = null;
      this.newFile = null;
      useAlert(this.$t('CANNED_MGMT.EDIT.FORM.ATTACHED_FILE.REMOVED_MESSAGE'));
    },
    onFileChange(event) {
      this.newFile = event.target.files[0];
      this.currentFilePath = this.newFile ? this.newFile.name : null;
      console.log('onFileChange - event.target.files[0]:', event.target.files[0]); // Log en onFileChange
      console.log('onFileChange - this.newFile:', this.newFile); // Log en onFileChange
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
          <div class="flex items-center justify-between p-2 border rounded-md bg-slate-50 dark:bg-slate-800">
            <span>{{ getFileNameFromPath(currentFilePath) }}</span>
            <woot-button class="clear secondary" icon="dismiss" @click.prevent="removeAttachedFile">
              {{ $t('CANNED_MGMT.EDIT.FORM.ATTACHED_FILE.REMOVE_BUTTON') }}
            </woot-button>
          </div>
        </div>
        <div v-else class="w-full mt-4">
          <p>{{ $t('CANNED_MGMT.EDIT.FORM.NO_ATTACHED_FILE.LABEL') }}</p>
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
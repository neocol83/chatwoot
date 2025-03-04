<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';

import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../components/Modal.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

export default {
  components: {
    WootSubmitButton,
    Modal,
    WootMessageEditor,
    // ¡ELIMINAMOS WootFileUpload de components!
  },
  props: {
    responseContent: {
      type: String,
      default: '',
    },
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      shortCode: '',
      content: this.responseContent || '',
      addCanned: {
        showLoading: false,
        message: '',
      },
      show: true,
      cannedFile: null, // Usamos cannedFile
      // ¡ELIMINAMOS fileInput ref, ya no es necesario!
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
  methods: {
    resetForm() {
      this.shortCode = '';
      this.content = '';
      this.cannedFile = null;
      this.v$.shortCode.$reset();
      this.v$.content.$reset();
    },
    handleFileChange(event) {
      this.cannedFile = event.target.files[0]; // Guardar el archivo en cannedFile
    },
    addCannedResponse() {
      const vm = this;
      vm.addCanned.showLoading = true;

      const formData = new FormData();
      formData.append('canned_response[short_code]', this.shortCode);
      formData.append('canned_response[content]', this.content);
      if (this.cannedFile) {
        formData.append('canned_response[canned_file]', this.cannedFile);
      }

      this.$store.dispatch('createCannedResponse', formData, { // Usamos this.$store.dispatch
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      })
        .then(() => {
          vm.addCanned.showLoading = false;
          useAlert(vm.$t('CANNED_MGMT.ADD.API.SUCCESS_MESSAGE'));
          vm.resetForm();
          vm.onClose();
        })
        .catch(error => {
          vm.addCanned.showLoading = false;
          const errorMessage =
            error?.message || vm.$t('CANNED_MGMT.ADD.API.ERROR_MESSAGE');
          useAlert(errorMessage);
        });
    },
    onDialogClose() {
      this.onClose();
    },
  },
};
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('CANNED_MGMT.ADD.TITLE')"
        :header-content="$t('CANNED_MGMT.ADD.DESC')"
      />
      <form class="flex flex-col w-full" @submit.prevent="addCannedResponse()">
        <div class="w-full">
          <label :class="{ error: v$.shortCode.$error }">
            {{ $t('CANNED_MGMT.ADD.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model.trim="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.SHORT_CODE.PLACEHOLDER')"
              @input="v$.shortCode.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.content.$error }">
            {{ $t('CANNED_MGMT.ADD.FORM.CONTENT.LABEL') }}
          </label>
          <div class="editor-wrap">
            <WootMessageEditor
              v-model="content"
              class="message-editor [&>div]:px-1"
              :class="{ editor_warning: v$.content.$error }"
              enable-variables
              :enable-canned-responses="false"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.CONTENT.PLACEHOLDER')"
              @blur="v$.content.$touch"
            />
          </div>
        </div>

        <div class="w-full mt-4">
          <label>  {{ $t('CANNED_MGMT.ADD.FORM.FILE_UPLOAD.LABEL') }}
            <input  type="file"
              accept="image/*,application/pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt"
              @change="handleFileChange"
            />
          </label>
          <p v-if="cannedFile">
            {{ $t('CANNED_MGMT.ADD.FORM.FILE_UPLOAD.SELECTED_FILE') }}: {{ cannedFile.name }}
          </p>
        </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <WootSubmitButton
            :disabled="
              v$.content.$invalid ||
              v$.shortCode.$invalid ||
              addCanned.showLoading
            "
            :button-text="$t('CANNED_MGMT.ADD.FORM.SUBMIT')"
            :loading="addCanned.showLoading"
          />
          <button class="button clear" @click.prevent="onClose">
            {{ $t('CANNED_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
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
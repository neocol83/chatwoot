<script setup>
import { useAlert } from 'dashboard/composables';
import AddCanned from './AddCanned.vue';
import EditCanned from './EditCanned.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'dashboard/composables/useI18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const showAddPopup = ref(false);
const loading = ref({});
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const activeResponse = ref({});
const cannedResponseAPI = ref({ message: '' });

const sortOrder = ref('asc');
const records = computed(() =>
  getters.getSortedCannedResponses.value(sortOrder.value)
);
const uiFlags = computed(() => getters.getUIFlags.value);

const deleteConfirmText = computed(
  () =>
    `${t('CANNED_MGMT.DELETE.CONFIRM.YES')} ${activeResponse.value.short_code}`
);

const deleteRejectText = computed(
  () =>
    `${t('CANNED_MGMT.DELETE.CONFIRM.NO')} ${activeResponse.value.short_code}`
);

const deleteMessage = computed(() => {
  return ` ${activeResponse.value.short_code} ? `;
});

const toggleSort = () => {
  sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
};

const fetchCannedResponses = async () => {
  try {
    await store.dispatch('getCannedResponse');
  } catch (error) {
    // Ignore Error
  }
};

onMounted(() => {
        fetchCannedResponses();
    });

const showAlertMessage = message => {
  loading[activeResponse.value.id] = false;
  activeResponse.value = {};
  cannedResponseAPI.value.message = message;
  useAlert(message);
};

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  activeResponse.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  activeResponse.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteCannedResponse = async id => {
  try {
    await store.dispatch('deleteCannedResponse', id);
    showAlertMessage(t('CANNED_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CANNED_MGMT.DELETE.API.ERROR_MESSAGE');
    showAlertMessage(errorMessage);
  }
};

const confirmDeletion = () => {
  loading[activeResponse.value.id] = true;
  closeDeletePopup();
  deleteCannedResponse(activeResponse.value.id);
};
</script>

<template>
  <div class="flex-1 overflow-auto">
    <BaseSettingsHeader
      :title="$t('CANNED_MGMT.HEADER')"
      :description="$t('CANNED_MGMT.DESCRIPTION')"
      :link-text="$t('CANNED_MGMT.LEARN_MORE')"
      feature-name="canned_responses"
    >
      <template #actions>
        <woot-button
          class="button nice rounded-md"
          icon="add-circle"
          @click="openAddPopup"
        >
          {{ $t('CANNED_MGMT.HEADER_BTN_TXT') }}
        </woot-button>
      </template>
    </BaseSettingsHeader>

    <div class="mt-6 flex-1">
      <woot-loading-state
        v-if="uiFlags.fetchingList"
        :message="$t('CANNED_MGMT.LOADING')"
      />
      <p
        v-else-if="!records.length"
        class="flex flex-col items-center justify-center h-full text-base text-slate-600 dark:text-slate-300 py-8"
      >
        {{ $t('CANNED_MGMT.LIST.404') }}
      </p>
      <table
        v-else
        class="min-w-full overflow-x-auto divide-y divide-slate-75 dark:divide-slate-700"
      >
        <thead>
          <th
            v-for="thHeader in $t('CANNED_MGMT.LIST.TABLE_HEADER')"
            :key="thHeader"
            class="py-4 pr-4 text-left font-semibold text-slate-700 dark:text-slate-300"
          >
            <span v-if="thHeader !== $t('CANNED_MGMT.LIST.TABLE_HEADER[0]')">
              {{ thHeader }}
            </span>

            <button
              v-if="thHeader === $t('CANNED_MGMT.LIST.TABLE_HEADER[0]')"
              class="flex items-center p-0 cursor-pointer"
              @click="toggleSort"
            >
              <span class="mb-0">
                {{ thHeader }}
              </span>
              <fluent-icon
                class="ml-2"
                :icon="sortOrder === 'desc' ? 'chevron-up' : 'chevron-down'"
              />
            </button>
          </th>
        </thead>
        <tbody
          class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300"
        >
          <tr
            v-for="(cannedItem, index) in records"
            :key="cannedItem.short_code"
          >
            <td
              class="py-4 pr-4 truncate max-w-xs font-medium"
              :title="cannedItem.short_code"
            >
              {{ cannedItem.short_code }}
            </td>
            <td class="py-4 pr-4 md:break-all whitespace-normal">
              {{ cannedItem.content }}
            </td>
            <td class="py-4 flex justify-end gap-1">
              <woot-button
                v-tooltip.top="$t('CANNED_MGMT.EDIT.BUTTON_TEXT')"
                variant="smooth"
                size="tiny"
                color-scheme="secondary"
                icon="edit"
                @click="openEditPopup(cannedItem)"
              />
              <woot-button
                v-tooltip.top="$t('CANNED_MGMT.DELETE.BUTTON_TEXT')"
                variant="smooth"
                color-scheme="alert"
                size="tiny"
                icon="dismiss-circle"
                class-names="grey-btn"
                :is-loading="loading[cannedItem.id]"
                @click="openDeletePopup(cannedItem, index)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <AddCanned :on-close="hideAddPopup" />
    </woot-modal>

    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <EditCanned
        v-if="showEditPopup"
        :id="activeResponse.id"
        :edshort-code="activeResponse.short_code"
        :edcontent="activeResponse.content"
        :edFilePath="activeResponse.file_path"
        :on-close="hideEditPopup"
      />
    </woot-modal>

    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('CANNED_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('CANNED_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>

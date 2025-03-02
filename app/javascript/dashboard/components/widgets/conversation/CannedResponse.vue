<script>
import { mapGetters } from 'vuex';
import MentionBox from '../mentions/MentionBox.vue';

export default {
  components: { MentionBox },
  props: {
    searchKey: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      cannedMessages: 'getCannedResponses',
    }),
    items() {
      return this.cannedMessages.map(cannedMessage => ({
        label: cannedMessage.short_code,
        key: cannedMessage.short_code,
        description: cannedMessage.content,
      }));
    },
  },
  watch: {
    searchKey() {
      this.fetchCannedResponses();
    },
  },
  mounted() {
    this.fetchCannedResponses();
  },
  methods: {
    fetchCannedResponses() {
      this.$store.dispatch('getCannedResponse', { searchKey: this.searchKey });
    },
    handleMentionClick(item = {}) {
      // Buscar el cannedMessage completo que corresponde al item seleccionado
      const selectedCannedMessage = this.cannedMessages.find(
        (cannedMessage) => cannedMessage.short_code === item.key
      );

      // Imprimir para verificar que estamos encontrando el cannedMessage correcto (OPCIONAL - para depuración)
      console.log('Selected cannedMessage from CannedResponse:', selectedCannedMessage);

      this.$emit('click', selectedCannedMessage); // MODIFICADO: Emitir el objeto cannedMessage completo
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <MentionBox
    v-if="items.length"
    :items="items"
    @mentionSelect="handleMentionClick"
  />
</template>

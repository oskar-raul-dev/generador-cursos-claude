import { shallowMount } from '@vue/test-utils';
import App from '@/App.vue';

describe('App.vue', function () {
  it('renders the title', function () {
    const wrapper = shallowMount(App);
    expect(wrapper.text()).toContain('phase11-vue2-min');
  });
});

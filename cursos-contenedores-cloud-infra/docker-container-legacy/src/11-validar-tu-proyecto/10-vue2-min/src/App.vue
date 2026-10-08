<template>
  <div id="app">
    <h1>{{ title }}</h1>
    <p>{{ message }}</p>
  </div>
</template>

<script>
export default {
  name: 'App',
  data: function () {
    return {
      title: 'phase11-vue2-min',
      message: 'Vue 2 corriendo dentro del contenedor legacy'
    };
  }
};
</script>

<style>
#app {
  font-family: sans-serif;
}
</style>

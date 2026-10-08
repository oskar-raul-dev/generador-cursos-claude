import React from 'react';

// Class component a propósito: React 16.13 ya tiene hooks, pero el código real
// de 2019 que vas a mantener está lleno de clases.
class App extends React.Component {
  render() {
    return (
      <div className="App">
        <h1>phase11-react16-min</h1>
        <p>React 16 corriendo dentro del contenedor legacy</p>
      </div>
    );
  }
}

export default App;

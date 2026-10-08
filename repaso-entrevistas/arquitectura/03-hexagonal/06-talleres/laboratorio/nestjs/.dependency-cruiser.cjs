// La regla de dependencias como prueba (el ArchUnit de este sabor): `npm run arch` falla si el
// núcleo importa Nest, Prisma, un driver o un adaptador.
module.exports = {
  forbidden: [
    {
      name: "domain-depends-on-nothing-outside",
      severity: "error",
      from: { path: "^src/domain/" },
      to: { path: "^src/(application|infrastructure)/|^node_modules/(@nestjs|@prisma|mongodb|redis|jose|class-validator)" },
    },
    {
      name: "application-does-not-know-infrastructure",
      severity: "error",
      from: { path: "^src/application/" },
      to: { path: "^src/infrastructure/|^node_modules/(@nestjs|@prisma|mongodb|redis|jose|class-validator|express)" },
    },
    {
      name: "inbound-does-not-touch-outbound",
      severity: "error",
      from: { path: "^src/infrastructure/inbound/" },
      to: { path: "^src/infrastructure/outbound/" },
    },
  ],
  options: {
    doNotFollow: { path: "node_modules" },
    tsConfig: { fileName: "tsconfig.json" },
    exclude: { path: "\\.test\\.ts$|/generated/" },
  },
};

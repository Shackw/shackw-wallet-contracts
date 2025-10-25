import eslintPluginTs from "@typescript-eslint/eslint-plugin";
import parserTs from "@typescript-eslint/parser";
import eslintPluginImport from "eslint-plugin-import";

export default [
  {
    files: ["**/*.ts"],
    ignores: ["typechain-types/**", "artifacts/**", "cache/**", "dist/**"],
    languageOptions: {
      parser: parserTs,
      parserOptions: {
        project: "./tsconfig.json",
        sourceType: "module",
      },
    },
    plugins: {
      "@typescript-eslint": eslintPluginTs,
      import: eslintPluginImport,
    },
    rules: {
      "no-console": "off",
      "@typescript-eslint/no-var-requires": "off",
      "@typescript-eslint/return-await": "off",
      "@typescript-eslint/no-unnecessary-type-assertion": "off",
      "@typescript-eslint/require-array-sort-compare": [
        "error",
        {
          ignoreStringArrays: true,
        },
      ],
      "@typescript-eslint/naming-convention": "off",
      "@typescript-eslint/no-non-null-assertion": "off",
      "@typescript-eslint/restrict-template-expressions": [
        "error",
        {
          allowNumber: true,
          allowBoolean: true,
          allowNullish: true,
        },
      ],

      "import/order": [
        "warn",
        {
          groups: [
            "builtin",
            "external",
            "internal",
            "parent",
            "sibling",
            "index",
            "object",
            "type",
          ],
          pathGroups: [
            {
              pattern: "@/**",
              group: "internal",
            },
          ],
          pathGroupsExcludedImportTypes: ["builtin"],
          "newlines-between": "always",
          alphabetize: {
            order: "asc",
            caseInsensitive: true,
          },
        },
      ],

      "@typescript-eslint/no-unused-vars": [
        "warn",
        {
          vars: "all",
          args: "after-used",
          ignoreRestSiblings: true,
          varsIgnorePattern: "^_",
          argsIgnorePattern: "^_",
        },
      ],
    },
  },
];

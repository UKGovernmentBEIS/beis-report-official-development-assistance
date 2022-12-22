import { babel } from "@rollup/plugin-babel";
import commonjs from "@rollup/plugin-commonjs";
import resolve from "@rollup/plugin-node-resolve";

export default {
  input: "app/javascript/application.js",
  output: {
    file: "app/assets/builds/application.js",
    format: "es",
    inlineDynamicImports: true,
    sourcemap: true,
  },
  plugins: [
    commonjs(),
    babel({
      babelHelpers: "runtime",
      exclude: "node_modules/**",
      presets: [
        [
          "@babel/preset-env",
          {
            useBuiltIns: "usage",
            corejs: "3",
          },
        ],
      ],
      plugins: ["@babel/plugin-transform-runtime"],
    }),
    resolve(),
  ],
};

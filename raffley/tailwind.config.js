// tailwind.config.js (project root)
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./lib/raffley_web/**/*.heex",
    "./lib/raffley_web/**/*.ex"
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require("./assets/vendor/daisyui.js")
  ],
};

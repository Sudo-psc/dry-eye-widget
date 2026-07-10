import { renderToString } from "react-dom/server";
import App from "./App";
import { LanguageProvider } from "./i18n/LanguageContext";
import "./styles.css";

export function render() {
  return renderToString(
    <LanguageProvider initialLang="pt">
      <App />
    </LanguageProvider>,
  );
}

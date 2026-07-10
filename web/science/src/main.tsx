import { StrictMode } from "react";
import { hydrateRoot } from "react-dom/client";
import App from "./App";
import { LanguageProvider } from "./i18n/LanguageContext";
import "./styles.css";

const root = document.getElementById("root");

if (!root) {
  throw new Error("Science page root element was not found.");
}

hydrateRoot(
  root,
  <StrictMode>
    <LanguageProvider>
      <App />
    </LanguageProvider>
  </StrictMode>,
);

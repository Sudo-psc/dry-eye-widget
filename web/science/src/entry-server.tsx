import { renderToString } from "react-dom/server";
import App from "./App";
import "./styles.css";

export function render() {
  return renderToString(<App />);
}

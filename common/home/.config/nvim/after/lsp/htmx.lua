-- htmx-lsp ships with a broad filetype list copied from Tailwind. Keep it to
-- files where HTMX attributes actually live so it does not attach to Markdown
-- or TypeScript buffers.
return {
  filetypes = { "html", "templ", "htmldjango" },
}

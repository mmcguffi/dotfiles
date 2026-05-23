<%*
const daily = tp.app.internalPlugins.getEnabledPluginById("daily-notes")?.options;

if (daily) {
  const folder = daily.folder || "";
  const format = daily.format || "YYYY-MM-DD";
  const fileName = window.moment().format(format);
  const dailyPath = [folder, `${fileName}.md`].filter(Boolean).join("/");
  let file = tp.app.vault.getAbstractFileByPath(dailyPath);
  const shouldOpenHomepage = !file;

  if (!file) {
    const folderPath = dailyPath.split("/").slice(0, -1).join("/");
    if (folderPath && !tp.app.vault.getAbstractFileByPath(folderPath)) {
      await tp.app.vault.createFolder(folderPath);
    }

    file = await tp.app.vault.create(dailyPath, "");
  }

  if (file) {
    const existing = await tp.app.vault.read(file);
    const rawTemplate = existing.includes("<%") && existing.includes("rollover_todos");
    const emptySkeleton = existing.trim() === `# ${file.basename}\n\n## #todos`;

    if (!existing.trim() || rawTemplate || emptySkeleton) {
      const dailyTp = Object.create(tp);
      dailyTp.config = Object.assign({}, tp.config, { target_file: file });
      dailyTp.file = Object.create(tp.file);
      dailyTp.file.title = file.basename;
      dailyTp.file.path = (relative = false) => relative ? file.path : file.path;

      const content = await tp.user.rollover_todos(dailyTp);

      if (content !== existing) {
        await tp.app.vault.modify(file, content);
      }
    }

    if (shouldOpenHomepage) {
      const commandId = "homepage:open-homepage";
      if (tp.app.commands.findCommand(commandId)) {
        await tp.app.commands.executeCommandById(commandId);
      } else {
        const leaf = tp.app.workspace.getLeaf(false);
        await leaf.openFile(file);
      }
    }
  }
}
%>

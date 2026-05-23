const CONFIG = {
  dailyFolder: "daily",
  doneFolder: "dones",
  dateFormat: "YYYY-MM-DD, ddd",
  todosHeading: /^#{1,6}\s+#todos\s*$/i,
};

const TASK_RE = /^(\s*)-\s+\[([ xX])\]/;

module.exports = async function (tp) {
  const app = tp.app;
  const targetFile = tp.config?.target_file;
  const currentPath = targetFile?.path ?? tp.file.path(true);
  const currentDate = parseDailyDate(targetFile?.basename ?? tp.file.title);

  const files = app.vault.getMarkdownFiles()
    .filter(f => isPreviousDailyFile(f, currentPath, currentDate))
    .sort((a, b) => parseDailyDate(b.basename).diff(parseDailyDate(a.basename)));

  if (!files.length) return "";

  const previous = files[0];
  const text = await app.vault.read(previous);
  const todoBlock = extractTodoBlock(text) ?? text;
  const { carried, completedTrees } = removeCompletedTaskTrees(todoBlock);

  await archiveCompletedTrees(app, previous, completedTrees);

  return carried;
};

function parseDailyDate(basename) {
  return window.moment(basename, CONFIG.dateFormat, true);
}

function isPreviousDailyFile(file, currentPath, currentDate) {
  if (!file.path.startsWith(CONFIG.dailyFolder + "/")) return false;
  if (file.path === currentPath) return false;

  const fileDate = parseDailyDate(file.basename);
  if (!fileDate.isValid()) return false;

  return !currentDate.isValid() || fileDate.isBefore(currentDate, "day");
}

function extractTodoBlock(text) {
  const lines = text.split("\n");
  const start = lines.findIndex(l => CONFIG.todosHeading.test(l.trim()));
  if (start === -1) return null;

  const startLevel = lines[start].match(/^#+/)[0].length;
  const out = [];

  for (let i = start + 1; i < lines.length; i++) {
    const heading = lines[i].match(/^(#{1,6})\s+/);
    if (heading && heading[1].length <= startLevel) break;
    out.push(lines[i]);
  }

  return out.join("\n");
}

function removeCompletedTaskTrees(text) {
  if (!text.trim()) return { carried: "", completedTrees: [] };

  const lines = text.split("\n");
  const nodes = parseTaskNodes(lines);

  if (!nodes.length) return { carried: "", completedTrees: [] };

  const dropLines = new Set();
  const completedTrees = [];

  for (const node of nodes) {
    if (!node.parent && isFullyChecked(node)) {
      completedTrees.push(markTaskTreeForRemoval(node, lines, dropLines));
    }
  }

  const carriedLines = lines.filter((_, index) => !dropLines.has(index));

  while (carriedLines.length && !carriedLines[carriedLines.length - 1].trim()) {
    carriedLines.pop();
  }

  const carried = carriedLines.length ? `${carriedLines.join("\n")}\n` : "";

  return { carried, completedTrees };
}

function parseTaskNodes(lines) {
  const nodes = [];
  const stack = [];

  for (let index = 0; index < lines.length; index++) {
    const match = lines[index].match(TASK_RE);
    if (!match) continue;

    const node = {
      index,
      indent: indentationWidth(match[1]),
      checked: match[2].toLowerCase() === "x",
      children: [],
      parent: null,
    };

    while (stack.length && stack[stack.length - 1].indent >= node.indent) {
      stack.pop();
    }

    if (stack.length) {
      node.parent = stack[stack.length - 1];
      node.parent.children.push(node);
    }

    nodes.push(node);
    stack.push(node);
  }

  return nodes;
}

function indentationWidth(whitespace) {
  return [...whitespace].reduce((width, char) => width + (char === "\t" ? 4 : 1), 0);
}

function isFullyChecked(node) {
  return node.checked && node.children.every(isFullyChecked);
}

function markTaskTreeForRemoval(node, lines, dropLines) {
  let end = lines.length;

  for (let index = node.index + 1; index < lines.length; index++) {
    const line = lines[index];
    if (!line.trim()) continue;

    const indent = indentationWidth(line.match(/^\s*/)[0]);
    if (indent <= node.indent) {
      end = index;
      break;
    }
  }

  while (end > node.index + 1 && !lines[end - 1].trim()) {
    end--;
  }

  const removalEnd = shouldDropFollowingBlankLine(node.index, end, lines)
    ? end + 1
    : end;

  for (let index = node.index; index < removalEnd; index++) {
    dropLines.add(index);
  }

  return lines.slice(node.index, end).join("\n");
}

function shouldDropFollowingBlankLine(start, end, lines) {
  if (start === 0 || end >= lines.length) return false;

  return !lines[start - 1].trim() && !lines[end].trim();
}

async function archiveCompletedTrees(app, sourceFile, completedTrees) {
  const blocks = completedTrees
    .map(block => block.trimEnd())
    .filter(Boolean);

  if (!blocks.length) return;

  await ensureFolder(app, CONFIG.doneFolder);

  const archivePath = `${CONFIG.doneFolder}/${sourceFile.basename}.md`;
  let archiveFile = app.vault.getAbstractFileByPath(archivePath);
  let existing = "";

  if (archiveFile) {
    existing = await app.vault.read(archiveFile);
  } else {
    archiveFile = await app.vault.create(archivePath, "");
  }

  const archived = archivedBlocks(existing);
  const additions = blocks.filter(block => !archived.has(block));
  if (!additions.length) return;

  const prefix = existing.trim()
    ? `${existing.trimEnd()}\n\n---\n\n`
    : `# ${sourceFile.basename}\n\n`;
  const content = `${prefix}${additions.join("\n\n---\n\n")}\n`;

  await app.vault.modify(archiveFile, content);
}

function archivedBlocks(existing) {
  const body = existing.replace(/^# .*\n\n/, "").trim();
  if (!body) return new Set();

  return new Set(body.split(/\n\n---\n\n/).map(block => block.trimEnd()));
}

async function ensureFolder(app, folderPath) {
  if (app.vault.getAbstractFileByPath(folderPath)) return;

  const parts = folderPath.split("/");
  let current = "";

  for (const part of parts) {
    current = current ? `${current}/${part}` : part;
    if (!app.vault.getAbstractFileByPath(current)) {
      await app.vault.createFolder(current);
    }
  }
}

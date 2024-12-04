import { readFile, writeFile } from 'fs/promises';
import { PDFDocument } from 'pdf-lib';

const pdfPath = process.argv[2];
const sourceDoc = await PDFDocument.load(await readFile(pdfPath));
const outDoc = await PDFDocument.create();
outDoc.addPage((await outDoc.copyPages(sourceDoc, [0]))[0]);
await writeFile(pdfPath, await outDoc.save());

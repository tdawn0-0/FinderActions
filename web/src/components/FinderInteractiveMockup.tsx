import React, { useState, useRef } from 'react';
import {
  Folder,
  FileText,
  FileCode,
  Image as ImageIcon,
  Terminal,
  Code2,
  Copy,
  Archive,
  ChevronLeft,
  ChevronRight,
  CheckCircle2,
  Clock,
  FileCheck2,
  Layers,
} from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FinderInteractiveMockupProps {
  lang: Language;
}

interface FileItem {
  id: string;
  name: string;
  size: string;
  type: string;
  iconType: 'image' | 'json' | 'sh' | 'pdf' | 'folder';
  matched: string[];
}

const FILES: FileItem[] = [
  { id: '1', name: 'hero-banner.png', size: '1.4 MB', type: 'PNG', iconType: 'image', matched: ['copy-path', 'copy-name', 'convert-webp', 'compress'] },
  { id: '2', name: 'api-schema.json', size: '18 KB', type: 'JSON', iconType: 'json', matched: ['open-vscode', 'copy-path', 'format-json', 'compress'] },
  { id: '3', name: 'deploy-pipeline.sh', size: '3.2 KB', type: 'Shell', iconType: 'sh', matched: ['open-terminal', 'open-vscode', 'copy-path', 'copy-name'] },
  { id: '4', name: 'design-spec.pdf', size: '4.8 MB', type: 'PDF', iconType: 'pdf', matched: ['copy-path', 'copy-name', 'compress'] },
  { id: '5', name: 'build-artifacts', size: '12 items', type: 'Folder', iconType: 'folder', matched: ['open-terminal', 'open-vscode', 'copy-path', 'compress'] },
];

export const FinderInteractiveMockup: React.FC<FinderInteractiveMockupProps> = ({ lang }) => {
  const t = translations[lang].demo;

  const [selectedFile, setSelectedFile] = useState<FileItem>(FILES[0]);
  const [menuOpen, setMenuOpen] = useState(true);
  const [menuPosition, setMenuPosition] = useState({ x: 260, y: 92 });
  const [toastKey, setToastKey] = useState<keyof typeof t.toastFeedback | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const openMenuForItem = (file: FileItem, clientX?: number, clientY?: number) => {
    setSelectedFile(file);
    if (containerRef.current && clientX !== undefined && clientY !== undefined) {
      const rect = containerRef.current.getBoundingClientRect();
      const clickX = Math.min(Math.max(clientX - rect.left, 24), Math.max(rect.width - 252, 24));
      const clickY = Math.min(Math.max(clientY - rect.top, 52), Math.max(rect.height - 250, 52));
      setMenuPosition({ x: clickX, y: clickY });
    } else {
      const rowIdx = FILES.findIndex((item) => item.id === file.id);
      setMenuPosition({ x: 240, y: 88 + Math.max(rowIdx, 0) * 38 });
    }
    setMenuOpen(true);
  };

  const handleActionClick = (key: keyof typeof t.toastFeedback) => {
    setMenuOpen(false);
    setToastKey(key);
    setTimeout(() => {
      setToastKey(null);
    }, 2600);
  };

  const getFileIcon = (type: FileItem['iconType']) => {
    switch (type) {
      case 'image':
        return <ImageIcon className="w-4 h-4 text-sky-400 shrink-0" />;
      case 'json':
        return <FileCode className="w-4 h-4 text-amber-400 shrink-0" />;
      case 'sh':
        return <Terminal className="w-4 h-4 text-emerald-400 shrink-0" />;
      case 'pdf':
        return <FileText className="w-4 h-4 text-rose-400 shrink-0" />;
      case 'folder':
        return <Folder className="w-4 h-4 text-[#0a84ff] fill-[#0a84ff]/20 shrink-0" />;
    }
  };

  return (
    <section id="demo" className="pb-12 md:pb-16 px-4 sm:px-6">
      <div className="max-w-5xl mx-auto">
        <div
          ref={containerRef}
          onClick={() => {
            if (menuOpen) setMenuOpen(false);
          }}
          className="relative rounded-2xl overflow-hidden glass-panel border border-white/12 shadow-[0_24px_60px_-16px_rgba(0,0,0,0.85)] bg-[#0f1118] select-none"
        >
          {toastKey && (
            <div
              role="status"
              className="absolute top-3 right-3 z-40 max-w-xs glass-dropdown rounded-xl px-3.5 py-2.5 flex items-center gap-2.5"
            >
              <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
              <span className="text-xs text-zinc-100 truncate">{t.toastFeedback[toastKey]}</span>
            </div>
          )}

          <div className="h-10 px-4 border-b border-white/8 bg-[#161922] flex items-center justify-between">
            <div className="flex items-center gap-2 w-20" aria-hidden="true">
              <span className="w-3 h-3 rounded-full bg-[#ff5f57]" />
              <span className="w-3 h-3 rounded-full bg-[#febc2e]" />
              <span className="w-3 h-3 rounded-full bg-[#28c840]" />
            </div>

            <div className="flex items-center gap-2 text-xs font-medium text-zinc-200">
              <div className="hidden sm:flex items-center text-zinc-500 gap-1 mr-1" aria-hidden="true">
                <ChevronLeft className="w-3.5 h-3.5" />
                <ChevronRight className="w-3.5 h-3.5" />
              </div>
              <Folder className="w-3.5 h-3.5 text-[#0a84ff]" />
              <span>Project-Assets</span>
            </div>

            <div className="w-20 text-right text-[11px] font-mono text-zinc-500">
              {FILES.length} items
            </div>
          </div>

          <div className="flex min-h-[340px] text-xs">
            <div className="w-44 bg-[#11131b] border-r border-white/6 p-3 hidden sm:flex flex-col gap-4 shrink-0" aria-hidden="true">
              <div>
                <div className="text-[10px] font-medium text-zinc-500 px-2 mb-1">
                  {t.sidebar.favorites}
                </div>
                <div className="flex flex-col gap-0.5 text-zinc-400">
                  <div className="flex items-center gap-2 px-2 py-1 rounded">
                    <Clock className="w-3.5 h-3.5 text-[#0a84ff]" />
                    <span>{t.sidebar.recents}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2 py-1 rounded">
                    <Layers className="w-3.5 h-3.5 text-[#0a84ff]" />
                    <span>{t.sidebar.applications}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2 py-1 rounded text-white bg-white/10 font-medium">
                    <Folder className="w-3.5 h-3.5 text-[#0a84ff]" />
                    <span>Project-Assets</span>
                  </div>
                  <div className="flex items-center gap-2 px-2 py-1 rounded">
                    <FileText className="w-3.5 h-3.5 text-[#0a84ff]" />
                    <span>{t.sidebar.documents}</span>
                  </div>
                </div>
              </div>

              <div>
                <div className="text-[10px] font-medium text-zinc-500 px-2 mb-1">
                  {t.sidebar.tags}
                </div>
                <div className="flex flex-col gap-0.5 text-zinc-400">
                  <div className="flex items-center gap-2 px-2 py-1">
                    <span className="w-2 h-2 rounded-full bg-[#0a84ff]" />
                    <span>{t.sidebar.work}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2 py-1">
                    <span className="w-2 h-2 rounded-full bg-emerald-500" />
                    <span>{t.sidebar.personal}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex-1 p-3 sm:p-4 bg-[#0c0e14] flex flex-col justify-between overflow-x-auto">
              <div className="rounded-lg overflow-hidden border border-white/6 divide-y divide-white/5">
                {FILES.map((file) => {
                  const isSelected = selectedFile.id === file.id;
                  return (
                    <button
                      key={file.id}
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        openMenuForItem(file, e.clientX || undefined, e.clientY || undefined);
                      }}
                      onContextMenu={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        openMenuForItem(file, e.clientX, e.clientY);
                      }}
                      className={`w-full flex items-center justify-between px-3 py-2.5 text-left transition-colors cursor-pointer ${
                        isSelected
                          ? 'bg-[#0a84ff] text-white'
                          : 'hover:bg-white/5 text-zinc-200'
                      }`}
                    >
                      <div className="flex items-center gap-2.5 min-w-0">
                        {getFileIcon(file.iconType)}
                        <span className="font-medium tracking-tight text-xs sm:text-[13px] truncate">
                          {file.name}
                        </span>
                      </div>
                      <div className="flex items-center gap-6 text-[11px] shrink-0 ml-4">
                        <span className={isSelected ? 'text-blue-100' : 'text-zinc-500'}>
                          {file.type}
                        </span>
                        <span className={`${isSelected ? 'text-blue-100' : 'text-zinc-400'} font-mono w-16 text-right`}>
                          {file.size}
                        </span>
                      </div>
                    </button>
                  );
                })}
              </div>

              <div className="mt-3 pt-2.5 border-t border-white/6 flex items-center justify-between text-[11px] text-zinc-500 font-mono">
                <span>~/Project-Assets/{selectedFile.name}</span>
                <span>{selectedFile.size}</span>
              </div>
            </div>
          </div>

          {menuOpen && (
            <div
              key={selectedFile.id}
              role="menu"
              style={{ top: `${menuPosition.y}px`, left: `${menuPosition.x}px` }}
              className="context-menu-pop absolute z-50 w-60 glass-dropdown rounded-lg py-1 text-xs text-zinc-100"
              onClick={(e) => e.stopPropagation()}
            >
              {selectedFile.matched.includes('open-terminal') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('openTerminal')}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer"
                >
                  <Terminal className="w-3.5 h-3.5 opacity-80 shrink-0" />
                  <span className="truncate">{t.menuItems.openTerminal}</span>
                </button>
              )}

              {selectedFile.matched.includes('open-vscode') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('openEditor')}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer"
                >
                  <Code2 className="w-3.5 h-3.5 opacity-80 shrink-0" />
                  <span className="truncate">{t.menuItems.openEditor}</span>
                </button>
              )}

              {selectedFile.matched.includes('copy-path') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('copyPath')}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer"
                >
                  <Copy className="w-3.5 h-3.5 opacity-80 shrink-0" />
                  <span className="truncate">{t.menuItems.copyPath}</span>
                </button>
              )}

              {selectedFile.matched.includes('copy-name') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('copyName')}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer"
                >
                  <FileCheck2 className="w-3.5 h-3.5 opacity-80 shrink-0" />
                  <span className="truncate">{t.menuItems.copyName}</span>
                </button>
              )}

              {selectedFile.matched.includes('convert-webp') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('convertWebp')}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer"
                >
                  <ImageIcon className="w-3.5 h-3.5 opacity-80 shrink-0" />
                  <span className="truncate">{t.menuItems.convertWebp}</span>
                </button>
              )}

              {selectedFile.matched.includes('format-json') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('formatJson')}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer"
                >
                  <FileCode className="w-3.5 h-3.5 opacity-80 shrink-0" />
                  <span className="truncate">{t.menuItems.formatJson}</span>
                </button>
              )}

              {selectedFile.matched.includes('compress') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('compress')}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer"
                >
                  <Archive className="w-3.5 h-3.5 opacity-80 shrink-0" />
                  <span className="truncate">{t.menuItems.compress}</span>
                </button>
              )}

              <div className="h-px bg-white/10 my-1" />

              <div className="px-3 py-1 text-zinc-500 flex items-center justify-between text-[11px]">
                <span>Get Info</span>
                <span className="font-mono text-[10px]">⌘I</span>
              </div>
              <div className="px-3 py-1 text-zinc-500 flex items-center justify-between text-[11px]">
                <span>Quick Look</span>
                <span className="font-mono text-[10px]">Space</span>
              </div>
            </div>
          )}
        </div>
      </div>
    </section>
  );
};

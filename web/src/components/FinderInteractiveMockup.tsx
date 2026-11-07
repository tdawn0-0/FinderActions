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
  { id: '1', name: 'hero-banner.png', size: '1.42 MB', type: 'PNG', iconType: 'image', matched: ['copy-path', 'copy-name', 'convert-webp', 'compress'] },
  { id: '2', name: 'api-schema.json', size: '0.02 MB', type: 'JSON', iconType: 'json', matched: ['open-vscode', 'copy-path', 'format-json', 'compress'] },
  { id: '3', name: 'deploy-pipeline.sh', size: '0.01 MB', type: 'Shell', iconType: 'sh', matched: ['open-terminal', 'open-vscode', 'copy-path', 'copy-name'] },
  { id: '4', name: 'design-spec.pdf', size: '4.80 MB', type: 'PDF', iconType: 'pdf', matched: ['copy-path', 'copy-name', 'compress'] },
  { id: '5', name: 'build-artifacts', size: '12.40 MB', type: 'Folder', iconType: 'folder', matched: ['open-terminal', 'open-vscode', 'copy-path', 'compress'] },
];

export const FinderInteractiveMockup: React.FC<FinderInteractiveMockupProps> = ({ lang }) => {
  const t = translations[lang].demo;

  const [selectedFile, setSelectedFile] = useState<FileItem>(FILES[0]);
  const [menuOpen, setMenuOpen] = useState(true);
  const [menuPosition, setMenuPosition] = useState({ x: 268, y: 96 });
  const [toastKey, setToastKey] = useState<keyof typeof t.toastFeedback | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const openMenuForItem = (file: FileItem, clientX?: number, clientY?: number) => {
    setSelectedFile(file);
    if (containerRef.current && clientX !== undefined && clientY !== undefined) {
      const rect = containerRef.current.getBoundingClientRect();
      const clickX = Math.min(Math.max(clientX - rect.left, 24), Math.max(rect.width - 264, 24));
      const clickY = Math.min(Math.max(clientY - rect.top, 52), Math.max(rect.height - 256, 52));
      setMenuPosition({ x: clickX, y: clickY });
    } else {
      const rowIdx = FILES.findIndex((item) => item.id === file.id);
      setMenuPosition({ x: 268, y: 96 + Math.max(rowIdx, 0) * 36 });
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

  const renderFileIcon = (type: FileItem['iconType'], selected: boolean) => {
    const cls = `w-4 h-4 shrink-0 ${selected ? 'text-white' : 'text-[#85858b]'}`;
    switch (type) {
      case 'image':
        return <ImageIcon className={cls} strokeWidth={1.5} />;
      case 'json':
        return <FileCode className={cls} strokeWidth={1.5} />;
      case 'sh':
        return <Terminal className={cls} strokeWidth={1.5} />;
      case 'pdf':
        return <FileText className={cls} strokeWidth={1.5} />;
      case 'folder':
        return <Folder className={cls} strokeWidth={1.5} />;
    }
  };

  return (
    <section id="demo" className="pb-20 md:pb-24 px-6 md:px-8">
      <div className="max-w-[1120px] mx-auto">
        <div
          ref={containerRef}
          onClick={() => {
            if (menuOpen) setMenuOpen(false);
          }}
          className="relative rounded-[16px] overflow-hidden bg-[#19191b] border border-[#ededed]/8 select-none"
        >
          {toastKey && (
            <div
              role="status"
              className="absolute top-3 right-3 z-40 max-w-sm rounded-[8px] px-3 h-9 bg-[#232325] border border-[#ededed]/10 flex items-center gap-2"
            >
              <span className="w-2 h-2 rounded-full bg-[#4cc38a] shrink-0" />
              <span className="text-[12px] leading-[16px] font-mono text-[#ededed] truncate">
                {t.toastFeedback[toastKey]}
              </span>
            </div>
          )}

          <div className="h-12 px-4 border-b border-[#ededed]/8 bg-[#19191b] flex items-center justify-between">
            <div className="flex items-center gap-2 w-24" aria-hidden="true">
              <span className="w-3 h-3 rounded-full bg-[#232325] border border-[#ededed]/12" />
              <span className="w-3 h-3 rounded-full bg-[#232325] border border-[#ededed]/12" />
              <span className="w-3 h-3 rounded-full bg-[#232325] border border-[#ededed]/12" />
            </div>

            <div className="flex items-center gap-2 text-[13px] leading-[20px] text-[#ededed]">
              <div className="hidden sm:flex items-center text-[#85858b] gap-1 mr-1" aria-hidden="true">
                <ChevronLeft className="w-4 h-4" strokeWidth={1.5} />
                <ChevronRight className="w-4 h-4" strokeWidth={1.5} />
              </div>
              <Folder className="w-4 h-4 text-[#85858b] shrink-0" strokeWidth={1.5} />
              <span className="font-medium">Project-Assets</span>
            </div>

            <div className="w-24 text-right text-[12px] leading-[16px] font-mono tabular-nums text-[#85858b]">
              {t.itemCount}
            </div>
          </div>

          <div className="flex min-h-[360px]">
            <div className="w-[224px] bg-[#0f0f10] border-r border-[#ededed]/8 p-4 hidden sm:flex flex-col gap-6 shrink-0" aria-hidden="true">
              <div>
                <div className="text-[12px] leading-[16px] text-[#85858b] px-2 mb-2">
                  {t.sidebar.locations}
                </div>
                <div className="flex flex-col gap-0.5 text-[13px] leading-[20px] text-[#a1a1a6]">
                  <div className="h-8 px-2 rounded-[8px] flex items-center gap-2.5">
                    <Clock className="w-4 h-4 text-[#85858b] shrink-0" strokeWidth={1.5} />
                    <span>{t.sidebar.recents}</span>
                  </div>
                  <div className="h-8 px-2 rounded-[8px] flex items-center gap-2.5">
                    <Layers className="w-4 h-4 text-[#85858b] shrink-0" strokeWidth={1.5} />
                    <span>{t.sidebar.applications}</span>
                  </div>
                  <div className="h-8 px-2 rounded-[8px] surface-active flex items-center gap-2.5 text-[#ededed] font-medium">
                    <Folder className="w-4 h-4 text-[#a1a1a6] shrink-0" strokeWidth={1.5} />
                    <span>Project-Assets</span>
                  </div>
                  <div className="h-8 px-2 rounded-[8px] flex items-center gap-2.5">
                    <FileText className="w-4 h-4 text-[#85858b] shrink-0" strokeWidth={1.5} />
                    <span>{t.sidebar.documents}</span>
                  </div>
                </div>
              </div>

              <div>
                <div className="text-[12px] leading-[16px] text-[#85858b] px-2 mb-2">
                  {t.sidebar.tags}
                </div>
                <div className="flex flex-col gap-0.5 text-[13px] leading-[20px] text-[#a1a1a6]">
                  <div className="h-8 px-2 rounded-[8px] flex items-center gap-2.5">
                    <span className="w-4 h-4 inline-flex items-center justify-center shrink-0">
                      <span className="w-2 h-2 rounded-full bg-[#0a84ff]" />
                    </span>
                    <span>{t.sidebar.work}</span>
                  </div>
                  <div className="h-8 px-2 rounded-[8px] flex items-center gap-2.5">
                    <span className="w-4 h-4 inline-flex items-center justify-center shrink-0">
                      <span className="w-2 h-2 rounded-full bg-[#4cc38a]" />
                    </span>
                    <span>{t.sidebar.personal}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex-1 p-4 bg-[#141415] flex flex-col justify-between overflow-x-auto">
              <div className="rounded-[8px] overflow-hidden border border-[#ededed]/8 divide-y divide-[#ededed]/8">
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
                      className={`w-full h-9 px-3 flex items-center justify-between text-left transition-colors cursor-pointer ${
                        isSelected
                          ? 'bg-[#0a84ff] text-white'
                          : 'bg-[#19191b] hover:bg-[#232325] text-[#ededed]'
                      }`}
                    >
                      <div className="flex items-center gap-2.5 min-w-0">
                        {renderFileIcon(file.iconType, isSelected)}
                        <span className="text-[13px] leading-[20px] truncate">
                          {file.name}
                        </span>
                      </div>
                      <div className="flex items-center gap-6 text-[12px] leading-[16px] shrink-0 ml-4">
                        <span className={isSelected ? 'text-white/80' : 'text-[#85858b]'}>
                          {file.type}
                        </span>
                        <span className={`${isSelected ? 'text-white/90' : 'text-[#a1a1a6]'} font-mono tabular-nums w-20 text-right`}>
                          {file.size}
                        </span>
                      </div>
                    </button>
                  );
                })}
              </div>

              <div className="mt-4 pt-3 border-t border-[#ededed]/8 flex items-center justify-between text-[12px] leading-[16px] text-[#85858b] font-mono tabular-nums">
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
              className="finder-menu absolute z-50 w-64 rounded-[10px] p-1 text-[13px] leading-[20px] text-[#ededed]"
              onClick={(e) => e.stopPropagation()}
            >
              {selectedFile.matched.includes('open-terminal') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('openTerminal')}
                  className="w-full h-8 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer group"
                >
                  <Terminal className="w-4 h-4 text-[#85858b] group-hover:text-white shrink-0" strokeWidth={1.5} />
                  <span className="truncate">{t.menuItems.openTerminal}</span>
                </button>
              )}

              {selectedFile.matched.includes('open-vscode') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('openEditor')}
                  className="w-full h-8 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer group"
                >
                  <Code2 className="w-4 h-4 text-[#85858b] group-hover:text-white shrink-0" strokeWidth={1.5} />
                  <span className="truncate">{t.menuItems.openEditor}</span>
                </button>
              )}

              {selectedFile.matched.includes('copy-path') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('copyPath')}
                  className="w-full h-8 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer group"
                >
                  <Copy className="w-4 h-4 text-[#85858b] group-hover:text-white shrink-0" strokeWidth={1.5} />
                  <span className="truncate">{t.menuItems.copyPath}</span>
                </button>
              )}

              {selectedFile.matched.includes('copy-name') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('copyName')}
                  className="w-full h-8 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer group"
                >
                  <FileCheck2 className="w-4 h-4 text-[#85858b] group-hover:text-white shrink-0" strokeWidth={1.5} />
                  <span className="truncate">{t.menuItems.copyName}</span>
                </button>
              )}

              {selectedFile.matched.includes('convert-webp') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('convertWebp')}
                  className="w-full h-8 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer group"
                >
                  <ImageIcon className="w-4 h-4 text-[#85858b] group-hover:text-white shrink-0" strokeWidth={1.5} />
                  <span className="truncate">{t.menuItems.convertWebp}</span>
                </button>
              )}

              {selectedFile.matched.includes('format-json') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('formatJson')}
                  className="w-full h-8 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer group"
                >
                  <FileCode className="w-4 h-4 text-[#85858b] group-hover:text-white shrink-0" strokeWidth={1.5} />
                  <span className="truncate">{t.menuItems.formatJson}</span>
                </button>
              )}

              {selectedFile.matched.includes('compress') && (
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => handleActionClick('compress')}
                  className="w-full h-8 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a84ff] hover:text-white text-left cursor-pointer group"
                >
                  <Archive className="w-4 h-4 text-[#85858b] group-hover:text-white shrink-0" strokeWidth={1.5} />
                  <span className="truncate">{t.menuItems.compress}</span>
                </button>
              )}

              <div className="h-px bg-[#ededed]/8 my-1" />

              <div className="h-7 px-2.5 flex items-center justify-between text-[12px] leading-[16px] text-[#85858b]">
                <span>Get Info</span>
                <kbd className="keycap">⌘I</kbd>
              </div>
              <div className="h-7 px-2.5 flex items-center justify-between text-[12px] leading-[16px] text-[#85858b]">
                <span>Quick Look</span>
                <kbd className="keycap">Space</kbd>
              </div>
            </div>
          )}
        </div>
      </div>
    </section>
  );
};

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
  Search, 
  ChevronLeft, 
  ChevronRight, 
  LayoutGrid,
  List as ListIcon,
  CheckCircle2,
  Sparkles,
  Clock,
  FileCheck2,
  Layers
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

export const FinderInteractiveMockup: React.FC<FinderInteractiveMockupProps> = ({ lang }) => {
  const t = translations[lang].demo;

  const files: FileItem[] = [
    { id: '1', name: 'hero-banner.png', size: '1.4 MB', type: 'PNG Image', iconType: 'image', matched: ['copy-path', 'copy-name', 'convert-webp', 'compress'] },
    { id: '2', name: 'api-schema.json', size: '18 KB', type: 'JSON Document', iconType: 'json', matched: ['open-vscode', 'copy-path', 'format-json', 'compress'] },
    { id: '3', name: 'deploy-pipeline.sh', size: '3.2 KB', type: 'Shell Script', iconType: 'sh', matched: ['open-terminal', 'open-vscode', 'copy-path', 'copy-name'] },
    { id: '4', name: 'design-spec.pdf', size: '4.8 MB', type: 'PDF Document', iconType: 'pdf', matched: ['copy-path', 'copy-name', 'compress'] },
    { id: '5', name: 'build-artifacts', size: '12 items', type: 'Folder', iconType: 'folder', matched: ['open-terminal', 'open-vscode', 'copy-path', 'compress'] },
  ];

  const [selectedFile, setSelectedFile] = useState<FileItem>(files[0]);
  const [menuOpen, setMenuOpen] = useState(false);
  const [menuPosition, setMenuPosition] = useState({ x: 220, y: 140 });
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const handleItemClick = (file: FileItem, e: React.MouseEvent) => {
    e.preventDefault();
    setSelectedFile(file);

    if (containerRef.current) {
      const rect = containerRef.current.getBoundingClientRect();
      const clickX = Math.min(Math.max(e.clientX - rect.left, 50), rect.width - 240);
      const clickY = Math.min(Math.max(e.clientY - rect.top, 60), rect.height - 300);
      setMenuPosition({ x: clickX, y: clickY });
    }
    setMenuOpen(true);
  };

  const handleActionClick = (feedback: string) => {
    setMenuOpen(false);
    setToastMessage(feedback);
    setTimeout(() => {
      setToastMessage(null);
    }, 3500);
  };

  const getFileIcon = (type: FileItem['iconType']) => {
    switch (type) {
      case 'image':
        return <ImageIcon className="w-5 h-5 text-sky-400" />;
      case 'json':
        return <FileCode className="w-5 h-5 text-amber-400" />;
      case 'sh':
        return <Terminal className="w-5 h-5 text-emerald-400" />;
      case 'pdf':
        return <FileText className="w-5 h-5 text-rose-400" />;
      case 'folder':
        return <Folder className="w-5 h-5 text-blue-400 fill-blue-400/20" />;
    }
  };

  return (
    <section id="demo" className="py-16 md:py-24 px-4 sm:px-6 relative">
      <div className="max-w-5xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-xs text-blue-400 font-medium mb-3">
            <Sparkles className="w-3.5 h-3.5" />
            <span>{t.tag}</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold text-white tracking-tight mb-3">
            {t.title}
          </h2>
          <p className="text-sm sm:text-base text-zinc-400 max-w-xl mx-auto">
            {t.description}
          </p>
        </div>

        {/* Finder Window Simulation */}
        <div 
          ref={containerRef}
          onClick={() => { if (menuOpen) setMenuOpen(false); }}
          className="relative rounded-2xl overflow-hidden glass-panel border border-white/15 shadow-[0_25px_60px_-15px_rgba(0,0,0,0.8)] backdrop-blur-3xl bg-[#0f121a]/95 select-none"
        >
          {/* macOS Toast Notification */}
          {toastMessage && (
            <div className="absolute top-4 right-4 z-40 max-w-sm glass-dropdown rounded-xl p-3.5 border border-white/20 shadow-2xl flex items-start gap-3 animate-in fade-in slide-in-from-top-3 duration-300">
              <img src="/app-icon.png" alt="FinderActions" className="w-9 h-9 rounded-lg shrink-0 shadow-sm" />
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-white tracking-tight">FinderActions</span>
                  <span className="text-[10px] text-zinc-400">now</span>
                </div>
                <p className="text-xs text-zinc-300 mt-0.5 leading-relaxed truncate">
                  {toastMessage}
                </p>
              </div>
              <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
            </div>
          )}

          {/* Window Titlebar */}
          <div className="h-11 px-4 border-b border-white/10 bg-[#171a25]/80 flex items-center justify-between">
            {/* Window Controls (Traffic Lights) */}
            <div className="flex items-center gap-2 w-28">
              <div className="w-3 h-3 rounded-full bg-[#ff5f57] border border-[#e0443e] cursor-pointer hover:opacity-80 transition-opacity" />
              <div className="w-3 h-3 rounded-full bg-[#febc2e] border border-[#d89e24] cursor-pointer hover:opacity-80 transition-opacity" />
              <div className="w-3 h-3 rounded-full bg-[#28c840] border border-[#1aab29] cursor-pointer hover:opacity-80 transition-opacity" />
            </div>

            {/* Title / Navigation */}
            <div className="flex items-center gap-2 text-xs font-medium text-zinc-300">
              <div className="flex items-center text-zinc-500 gap-1 mr-1">
                <ChevronLeft className="w-3.5 h-3.5 cursor-pointer hover:text-zinc-300" />
                <ChevronRight className="w-3.5 h-3.5 cursor-pointer hover:text-zinc-300" />
              </div>
              <Folder className="w-3.5 h-3.5 text-blue-400" />
              <span className="font-semibold text-white">Project-Assets</span>
            </div>

            {/* View Mode Controls & Search */}
            <div className="flex items-center gap-2">
              <div className="hidden sm:flex items-center bg-black/40 border border-white/10 rounded-md p-0.5 text-zinc-400">
                <button className="p-1 rounded hover:text-white"><LayoutGrid className="w-3 h-3" /></button>
                <button className="p-1 rounded bg-white/15 text-white shadow-sm"><ListIcon className="w-3 h-3" /></button>
              </div>
              <div className="relative">
                <Search className="w-3 h-3 text-zinc-500 absolute left-2 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Search"
                  readOnly
                  className="w-24 sm:w-32 bg-black/40 border border-white/10 rounded-md pl-6 pr-2 py-0.5 text-[11px] text-zinc-300 focus:outline-none"
                />
              </div>
            </div>
          </div>

          {/* Window Body: Sidebar + File View */}
          <div className="flex min-h-[380px] text-xs">
            {/* Sidebar */}
            <div className="w-48 bg-[#11141e]/70 border-r border-white/5 p-3 hidden sm:flex flex-col gap-4 shrink-0">
              <div>
                <div className="text-[10px] font-semibold text-zinc-500 uppercase tracking-wider px-2 mb-1">
                  {t.sidebar.favorites}
                </div>
                <div className="flex flex-col gap-0.5">
                  <div className="flex items-center gap-2 px-2 py-1 rounded text-zinc-400 hover:text-white hover:bg-white/5 cursor-pointer">
                    <Clock className="w-3.5 h-3.5 text-blue-400" />
                    <span>{t.sidebar.recents}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2 py-1 rounded text-zinc-400 hover:text-white hover:bg-white/5 cursor-pointer">
                    <Layers className="w-3.5 h-3.5 text-blue-400" />
                    <span>{t.sidebar.applications}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2 py-1 rounded text-white bg-blue-600/30 border border-blue-500/20 font-medium cursor-pointer">
                    <Folder className="w-3.5 h-3.5 text-blue-400" />
                    <span>Project-Assets</span>
                  </div>
                  <div className="flex items-center gap-2 px-2 py-1 rounded text-zinc-400 hover:text-white hover:bg-white/5 cursor-pointer">
                    <FileText className="w-3.5 h-3.5 text-blue-400" />
                    <span>{t.sidebar.documents}</span>
                  </div>
                </div>
              </div>

              <div>
                <div className="text-[10px] font-semibold text-zinc-500 uppercase tracking-wider px-2 mb-1">
                  {t.sidebar.tags}
                </div>
                <div className="flex flex-col gap-0.5">
                  <div className="flex items-center gap-2 px-2 py-1 text-zinc-400 hover:text-white cursor-pointer">
                    <span className="w-2 h-2 rounded-full bg-blue-500" />
                    <span>{t.sidebar.work}</span>
                  </div>
                  <div className="flex items-center gap-2 px-2 py-1 text-zinc-400 hover:text-white cursor-pointer">
                    <span className="w-2 h-2 rounded-full bg-emerald-500" />
                    <span>{t.sidebar.personal}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Main File Table */}
            <div className="flex-1 p-4 bg-[#0c0e15]/90 flex flex-col justify-between overflow-x-auto">
              <div>
                <div className="text-[11px] text-zinc-400 mb-2 flex items-center justify-between">
                  <span className="font-mono text-zinc-500">{t.hintClick}</span>
                  <span className="text-[10px] bg-white/10 px-2 py-0.5 rounded text-zinc-300">5 items</span>
                </div>

                <div className="border border-white/5 rounded-xl overflow-hidden divide-y divide-white/5">
                  {files.map((file) => {
                    const isSelected = selectedFile.id === file.id;
                    return (
                      <div
                        key={file.id}
                        onClick={(e) => handleItemClick(file, e)}
                        onContextMenu={(e) => handleItemClick(file, e)}
                        className={`flex items-center justify-between px-3 py-2.5 cursor-pointer transition-colors ${
                          isSelected 
                            ? 'bg-blue-600 text-white' 
                            : 'hover:bg-white/5 text-zinc-200'
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          {getFileIcon(file.iconType)}
                          <span className="font-medium tracking-tight text-xs sm:text-sm">
                            {file.name}
                          </span>
                        </div>
                        <div className="flex items-center gap-6 text-[11px]">
                          <span className={isSelected ? 'text-blue-100' : 'text-zinc-500'}>
                            {file.type}
                          </span>
                          <span className={isSelected ? 'text-blue-200 font-mono' : 'text-zinc-400 font-mono'}>
                            {file.size}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Status bar */}
              <div className="mt-4 pt-3 border-t border-white/5 flex items-center justify-between text-[11px] text-zinc-500">
                <span>Selected: <strong className="text-zinc-300 font-mono">{selectedFile.name}</strong></span>
                <span className="font-mono">Macintosh HD › Users › dev › Project-Assets</span>
              </div>
            </div>
          </div>

          {/* Authentic macOS Context Menu Overlay */}
          {menuOpen && (
            <div
              style={{ top: `${menuPosition.y}px`, left: `${menuPosition.x}px` }}
              className="absolute z-50 w-64 glass-dropdown rounded-xl py-1.5 border border-white/20 shadow-2xl text-xs text-zinc-200 animate-in fade-in zoom-in-95 duration-150 backdrop-blur-2xl bg-[#1e2230]/95"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="px-3 py-1 text-[10px] font-semibold text-zinc-400 uppercase tracking-wider flex items-center justify-between border-b border-white/10 mb-1">
                <span>{t.contextMenuHeader}</span>
                <span className="text-blue-400 font-mono">FinderActions</span>
              </div>

              {/* Quick Actions for Selected File */}
              {selectedFile.matched.includes('open-terminal') && (
                <button
                  onClick={() => handleActionClick(t.toastFeedback.openTerminal)}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-blue-600 hover:text-white text-left transition-colors group"
                >
                  <Terminal className="w-3.5 h-3.5 text-emerald-400 group-hover:text-white" />
                  <span>{t.menuItems.openTerminal}</span>
                </button>
              )}

              {selectedFile.matched.includes('open-vscode') && (
                <button
                  onClick={() => handleActionClick(t.toastFeedback.openEditor)}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-blue-600 hover:text-white text-left transition-colors group"
                >
                  <Code2 className="w-3.5 h-3.5 text-blue-400 group-hover:text-white" />
                  <span>{t.menuItems.openEditor}</span>
                </button>
              )}

              {selectedFile.matched.includes('copy-path') && (
                <button
                  onClick={() => handleActionClick(t.toastFeedback.copyPath)}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-blue-600 hover:text-white text-left transition-colors group"
                >
                  <Copy className="w-3.5 h-3.5 text-purple-400 group-hover:text-white" />
                  <span>{t.menuItems.copyPath}</span>
                </button>
              )}

              {selectedFile.matched.includes('copy-name') && (
                <button
                  onClick={() => handleActionClick(t.toastFeedback.copyName)}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-blue-600 hover:text-white text-left transition-colors group"
                >
                  <FileCheck2 className="w-3.5 h-3.5 text-indigo-400 group-hover:text-white" />
                  <span>{t.menuItems.copyName}</span>
                </button>
              )}

              {selectedFile.matched.includes('convert-webp') && (
                <button
                  onClick={() => handleActionClick(t.toastFeedback.convertWebp)}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-blue-600 hover:text-white text-left transition-colors group"
                >
                  <ImageIcon className="w-3.5 h-3.5 text-sky-400 group-hover:text-white" />
                  <span>{t.menuItems.convertWebp}</span>
                </button>
              )}

              {selectedFile.matched.includes('format-json') && (
                <button
                  onClick={() => handleActionClick(t.toastFeedback.formatJson)}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-blue-600 hover:text-white text-left transition-colors group"
                >
                  <FileCode className="w-3.5 h-3.5 text-amber-400 group-hover:text-white" />
                  <span>{t.menuItems.formatJson}</span>
                </button>
              )}

              {selectedFile.matched.includes('compress') && (
                <button
                  onClick={() => handleActionClick(t.toastFeedback.compress)}
                  className="w-full flex items-center gap-2.5 px-3 py-1.5 hover:bg-blue-600 hover:text-white text-left transition-colors group"
                >
                  <Archive className="w-3.5 h-3.5 text-rose-400 group-hover:text-white" />
                  <span>{t.menuItems.compress}</span>
                </button>
              )}

              {/* Standard macOS menu separator */}
              <div className="h-[1px] bg-white/10 my-1" />

              {/* Standard Finder actions */}
              <div className="px-3 py-1 text-zinc-500 flex items-center justify-between text-[11px]">
                <span>Get Info</span>
                <span className="font-mono text-[10px]">⌘I</span>
              </div>
              <div className="px-3 py-1 text-zinc-500 flex items-center justify-between text-[11px]">
                <span>Duplicate</span>
                <span className="font-mono text-[10px]">⌘D</span>
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

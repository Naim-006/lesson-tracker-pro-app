import { STATUS_COLORS, STATUS_LABELS } from '@/lib/utils';

interface StatusBadgeProps {
  status: string;
  className?: string;
}

export default function StatusBadge({ status, className = '' }: StatusBadgeProps) {
  const colorClass = STATUS_COLORS[status] || 'bg-gray-100 text-gray-800 border-gray-200';
  const label = STATUS_LABELS[status] || status;

  return (
    <span
      className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${colorClass} ${className}`}
    >
      {status === 'pending' && (
        <span className="w-1.5 h-1.5 bg-amber-500 rounded-full mr-1.5 animate-pulse" />
      )}
      {status === 'approved' && (
        <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full mr-1.5" />
      )}
      {status === 'rejected' && (
        <span className="w-1.5 h-1.5 bg-red-500 rounded-full mr-1.5" />
      )}
      {label}
    </span>
  );
}

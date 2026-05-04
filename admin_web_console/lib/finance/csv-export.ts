/**
 * CSV Export Utility for Finance Admin
 * Provides governed, client-side CSV generation from already-fetched read models.
 */

export function generateCsvData(headers: string[], rows: (string | number)[][]): string {
  const escapeCell = (cell: string | number) => {
    const str = String(cell);
    return str.includes(',') || str.includes('\n') || str.includes('"')
      ? `"${str.replace(/"/g, '""')}"`
      : str;
  };

  const csvRows = [
    headers.map(escapeCell).join(','),
    ...rows.map(row => row.map(escapeCell).join(',')),
  ];

  // Add BOM for Excel UTF-8 support
  return '\uFEFF' + csvRows.join('\n');
}

export function downloadCsv(filename: string, csvData: string) {
  const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  if (link.download !== undefined) {
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', filename);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
}

// Pengiriman email via Gmail SMTP (nodemailer, lazy require).
//
// - Kredensial HANYA dari env: SMTP_HOST/SMTP_PORT/SMTP_USER/SMTP_PASS.
//   Untuk Gmail pakai App Password (bukan password akun). Tanpa itu,
//   pengiriman jadi mode log-only (server tetap jalan, forgot tetap 200
//   generik agar tidak membocorkan keberadaan akun).
// - Template HTML + text fallback, Bahasa Indonesia, branded Japanese Study.

const APP_NAME = (process.env.APP_NAME || 'Japanese Study').trim() || 'Japanese Study';

function smtpConfigured() {
  return !!((process.env.SMTP_HOST || '').trim() &&
    (process.env.SMTP_USER || '').trim() &&
    (process.env.SMTP_PASS || '').trim());
}

function transport() {
  if (!smtpConfigured()) return null;
  let nodemailer = null;
  try {
    nodemailer = require('nodemailer');
  } catch (_) {
    console.error('[mail] nodemailer belum diinstall. Jalankan: npm install');
    return null;
  }
  const port = Number(process.env.SMTP_PORT || 587);
  return nodemailer.createTransport({
    host: (process.env.SMTP_HOST || '').trim(),
    port,
    secure: port === 465,
    auth: {
      user: (process.env.SMTP_USER || '').trim(),
      pass: (process.env.SMTP_PASS || '').trim(),
    },
  });
}

async function sendMail({ to, subject, html, text }) {
  const t = transport();
  const fromAddr = (process.env.SMTP_FROM || process.env.SMTP_USER || '').trim();
  if (!t) {
    console.log(`[mail] SKIP (SMTP kosong) to=${to} subject=${subject}`);
    return { sent: false, reason: 'SMTP_DISABLED' };
  }
  try {
    await t.sendMail({
      from: `"${APP_NAME}" <${fromAddr}>`,
      to,
      subject,
      text: text || '',
      html: html || '',
    });
    return { sent: true };
  } catch (e) {
    console.error('[mail] kirim gagal:', e && e.message ? e.message : e);
    return { sent: false, reason: 'SMTP_ERROR' };
  }
}

const shell = (title, bodyHtml) => `<!DOCTYPE html>
<html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title></head>
<body style="margin:0;padding:0;background:#f4f1ea;font-family:Arial,Helvetica,sans-serif;">
<div style="max-width:560px;margin:0 auto;padding:24px 16px;">
<div style="background:#1f2937;border-radius:16px 16px 0 0;padding:24px;text-align:center;">
<div style="font-size:36px;font-weight:bold;color:#fff;">日本語</div>
<div style="color:#fbbf24;font-weight:bold;letter-spacing:1px;">${APP_NAME}</div>
</div>
<div style="background:#fff;border-radius:0 0 16px 16px;padding:28px 24px;color:#1f2937;">
${bodyHtml}
<hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0;">
<p style="font-size:12px;color:#6b7280;margin:0;">Email otomatis, jangan dibalas. Bila kamu tidak meminta ini, abaikan email ini dan pastikan akunmu aman.</p>
</div></div></body></html>`;

function resetCodeTemplate({ name, code, minutes }) {
  const safeName = String(name || 'teman belajar').slice(0, 80);
  const subject = `Kode reset password ${APP_NAME}`;
  // PENTING: kode TIDAK dicantumkan di subject pada implementasi di bawah?
  // Justru dicantumkan agar terlihat di notifikasi HP. Risiko rendah karena
  // kode kedaluwarsa singkat + max percobaan + hanya ke inbox pemilik.
  const body = `
<h2 style="margin:0 0 8px;">Halo, ${safeName} 👋</h2>
<p>Kamu meminta reset password <b>${APP_NAME}</b>. Masukkan kode berikut di aplikasi:</p>
<div style="text-align:center;margin:20px 0;">
<span style="display:inline-block;font-size:34px;font-weight:bold;letter-spacing:10px;background:#fef3c7;color:#92400e;border:2px dashed #f59e0b;border-radius:12px;padding:12px 20px 12px 30px;">${code}</span>
</div>
<p>Kode berlaku <b>${minutes} menit</b> dan hanya bisa dipakai <b>satu kali</b>. Maksimal 5x salah tebak, setelah itu kode hangus dan kamu harus minta lagi.</p>
<p style="color:#b91c1c;"><b>Bukan kamu yang meminta?</b> Abaikan email ini — password-mu tetap aman dan tidak berubah.</p>`;
  const text = `Halo ${safeName},\n\nKode reset password ${APP_NAME} kamu: ${code}\nBerlaku ${minutes} menit, sekali pakai.\n\nBukan kamu yang meminta? Abaikan email ini.`;
  return { subject, html: shell('Reset password', body), text };
}

function passwordChangedTemplate({ name }) {
  const safeName = String(name || 'teman belajar').slice(0, 80);
  const subject = `Password ${APP_NAME} berhasil diubah`;
  const body = `
<h2 style="margin:0 0 8px;">Halo, ${safeName} 👋</h2>
<p>Password akun <b>${APP_NAME}</b> kamu <b>baru saja diubah</b>.</p>
<p>Semua sesi login lama otomatis dimatikan — kamu perlu masuk ulang di perangkat lain.</p>
<p style="color:#b91c1c;"><b>Bukan kamu yang mengubah?</b> Segera gunakan fitur <i>Lupa password</i> di aplikasi untuk mengambil alih akunmu, lalu hubungi admin.</p>`;
  const text = `Halo ${safeName},\n\nPassword akun ${APP_NAME} kamu baru saja diubah. Semua sesi lama dimatikan.\n\nBukan kamu? Segera gunakan fitur Lupa password di aplikasi.`;
  return { subject, html: shell('Password diubah', body), text };
}

function googleAccountNoticeTemplate({ name }) {
  const safeName = String(name || 'teman belajar').slice(0, 80);
  const subject = `Akun ${APP_NAME} kamu login dengan Google`;
  const body = `
<h2 style="margin:0 0 8px;">Halo, ${safeName} 👋</h2>
<p>Ada permintaan reset password untuk alamat email ini, tetapi akun <b>${APP_NAME}</b> kamu <b>login dengan Google</b> sehingga tidak punya password di server kami.</p>
<p>Untuk mengamankan akun, kelola password melalui <b>akun Google</b>-mu (myaccount.google.com), bukan dari aplikasi ini.</p>
<p style="color:#6b7280;">Bukan kamu yang meminta? Abaikan email ini.</p>`;
  const text = `Halo ${safeName},\n\nAkun ${APP_NAME} kamu login dengan Google sehingga tidak punya password di server kami. Kelola password via akun Google-mu.\n\nBukan kamu yang meminta? Abaikan email ini.`;
  return { subject, html: shell('Akun Google', body), text };
}

module.exports = {
  APP_NAME,
  smtpConfigured,
  sendMail,
  resetCodeTemplate,
  passwordChangedTemplate,
  googleAccountNoticeTemplate,
};

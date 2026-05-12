import nodemailer from 'nodemailer'

const PORTAL_URL = process.env.NEXT_PUBLIC_PORTAL_URL || 'http://localhost:3000'
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:8080'
const LOGO_URL = `${SITE_URL}/files/images/logo-cruzy.png`

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
})

const FROM = process.env.SMTP_FROM || 'Cruzy+ <noreply@cruzy.com>'

function baseLayout(content: string) {
  return `<!DOCTYPE html>
<html lang="en" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<!--[if gte mso 9]><xml><o:OfficeDocumentSettings><o:AllowPNG/><o:PixelPerInch>96</o:PixelPerInch></o:OfficeDocumentSettings></xml><![endif]-->
</head>
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Poppins',Helvetica,Arial,sans-serif;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" bgcolor="#f0f4f8" style="background:#f0f4f8;padding:40px 0;">
  <tr><td align="center">
    <!--[if mso]><table role="presentation" cellpadding="0" cellspacing="0" width="600" align="center"><tr><td><![endif]-->
    <table role="presentation" width="600" cellpadding="0" cellspacing="0" bgcolor="#ffffff" style="max-width:600px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 40px rgba(0,0,0,0.08);">
      <!-- Header -->
      <tr>
        <td bgcolor="#0f559a" style="background:#0f559a;background:linear-gradient(135deg,#0f559a 0%,#1a7fd4 100%);padding:40px 40px 30px;text-align:center;">
          <!--[if mso]><v:rect xmlns:v="urn:schemas-microsoft-com:vml" fill="true" stroke="false" style="width:600px;height:110px;"><v:fill type="gradient" color="#0f559a" color2="#1a7fd4" angle="135"/><v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true;"><center><![endif]-->
          <img src="${LOGO_URL}" alt="Cruzy+" width="180" style="display:inline-block;max-width:180px;" />
          <!--[if mso]></center></v:textbox></v:rect><![endif]-->
        </td>
      </tr>
      <!-- Body -->
      <tr>
        <td style="padding:40px 44px 20px;">
          ${content}
        </td>
      </tr>
      <!-- Divider -->
      <tr>
        <td style="padding:0 44px;">
          <div style="border-top:1px solid #e8ecf1;"></div>
        </td>
      </tr>
      <!-- Footer -->
      <tr>
        <td style="padding:24px 44px 36px;text-align:center;">
          <p style="margin:0 0 6px;font-size:13px;color:#9ba5b4;">Cruzy+ &bull; PO Box 35, Conway, AR 72033</p>
          <p style="margin:0 0 6px;font-size:13px;color:#9ba5b4;">
            <a href="tel:855-462-7899" style="color:#0f559a;text-decoration:none;">855-462-7899</a> &bull;
            <a href="mailto:info@cruzy.com" style="color:#0f559a;text-decoration:none;">info@cruzy.com</a>
          </p>
          <p style="margin:12px 0 0;font-size:12px;color:#b8c0cc;">&copy; ${new Date().getFullYear()} Cruzy. All rights reserved.</p>
        </td>
      </tr>
    </table>
    <!--[if mso]></td></tr></table><![endif]-->
  </td></tr>
</table>
</body>
</html>`
}

function buttonHtml(text: string, url: string) {
  return `<table role="presentation" cellpadding="0" cellspacing="0" style="margin:32px auto;">
  <tr>
    <td bgcolor="#dc1125" style="border-radius:10px;background:#dc1125;background:linear-gradient(135deg,#dc1125 0%,#e8334a 100%);" align="center">
      <!--[if mso]><v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="${url}" style="height:52px;v-text-anchor:middle;width:240px;" arcsize="19%" fillcolor="#dc1125" stroke="f"><w:anchorlock/><center style="color:#ffffff;font-family:Poppins,Helvetica,Arial,sans-serif;font-size:16px;font-weight:600;">${text}</center></v:roundrect><![endif]-->
      <!--[if !mso]><!-->
      <a href="${url}" target="_blank" style="display:inline-block;padding:16px 48px;font-family:'Poppins',Helvetica,Arial,sans-serif;font-size:16px;font-weight:600;color:#ffffff;text-decoration:none;border-radius:10px;letter-spacing:0.3px;">${text}</a>
      <!--<![endif]-->
    </td>
  </tr>
</table>`
}

export function passwordResetEmail(firstName: string, resetUrl: string) {
  const html = baseLayout(`
    <h1 style="margin:0 0 8px;font-family:'Montserrat','Poppins',Helvetica,sans-serif;font-size:26px;font-weight:700;color:#1a2b4a;">Reset Your Password</h1>
    <p style="margin:0 0 24px;font-size:15px;color:#5a6577;line-height:1.6;">Hi ${firstName || 'there'},</p>
    <p style="margin:0 0 8px;font-size:15px;color:#5a6577;line-height:1.6;">We received a request to reset your Cruzy+ portal password. Click the button below to choose a new one.</p>
    ${buttonHtml('Reset My Password', resetUrl)}
    <p style="margin:0 0 8px;font-size:13px;color:#9ba5b4;line-height:1.6;">This link expires in <strong>1 hour</strong>. If you didn&rsquo;t request a password reset, you can safely ignore this email.</p>
    <p style="margin:20px 0 0;font-size:13px;color:#b8c0cc;line-height:1.5;word-break:break-all;">Or copy this link: <a href="${resetUrl}" style="color:#0f559a;">${resetUrl}</a></p>
  `)

  return {
    subject: 'Reset Your Cruzy+ Password',
    html,
  }
}

export function welcomeEmail(firstName: string, setPasswordUrl: string, memberId: string) {
  const html = baseLayout(`
    <h1 style="margin:0 0 8px;font-family:'Montserrat','Poppins',Helvetica,sans-serif;font-size:26px;font-weight:700;color:#1a2b4a;">Welcome Aboard, ${firstName || 'Sailor'}! &#9875;</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#5a6577;line-height:1.6;">You&rsquo;re officially a <strong style="color:#0f559a;">Cruzy+ member</strong>. We&rsquo;re thrilled to have you with us.</p>

    <!-- Member card -->
    <!--[if mso]><v:rect xmlns:v="urn:schemas-microsoft-com:vml" fill="true" stroke="false" style="width:512px;height:80px;"><v:fill type="gradient" color="#0f559a" color2="#dc1125" angle="135"/><v:textbox inset="32px,28px,32px,28px" style="mso-fit-shape-to-text:true;"><![endif]-->
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" bgcolor="#0f559a" style="margin:0 0 24px;border-radius:12px;overflow:hidden;background:#0f559a;background:linear-gradient(135deg,#0f559a 0%,#1a7fd4 50%,#dc1125 100%);">
      <tr>
        <td style="padding:28px 32px;">
          <p style="margin:0 0 4px;font-size:11px;text-transform:uppercase;letter-spacing:1.5px;color:rgba(255,255,255,0.7);font-weight:600;">Member ID</p>
          <p style="margin:0;font-size:22px;font-weight:700;color:#ffffff;letter-spacing:1px;font-family:'Montserrat','Poppins',monospace;">${memberId}</p>
        </td>
      </tr>
    </table>
    <!--[if mso]></v:textbox></v:rect><![endif]-->

    <p style="margin:0 0 8px;font-size:15px;color:#5a6577;line-height:1.6;">To access your member portal &mdash; view bookings, manage payment methods, and track rewards &mdash; set your password below.</p>
    ${buttonHtml('Set My Password', setPasswordUrl)}
    <p style="margin:0 0 8px;font-size:13px;color:#9ba5b4;line-height:1.6;">This link expires in <strong>24 hours</strong>. If it expires, visit <a href="${PORTAL_URL}/forgot-password" style="color:#0f559a;">the portal</a> to request a new one.</p>

    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" bgcolor="#f7f9fc" style="margin:24px 0 0;background:#f7f9fc;border-radius:10px;">
      <tr>
        <td style="padding:20px 24px;">
          <p style="margin:0 0 10px;font-size:14px;font-weight:600;color:#1a2b4a;">What&rsquo;s next?</p>
          <table role="presentation" cellpadding="0" cellspacing="0">
            <tr><td style="padding:4px 0;font-size:14px;color:#5a6577;">&#10003;&ensp;Set your password &amp; log in</td></tr>
            <tr><td style="padding:4px 0;font-size:14px;color:#5a6577;">&#10003;&ensp;Browse upcoming cruises</td></tr>
            <tr><td style="padding:4px 0;font-size:14px;color:#5a6577;">&#10003;&ensp;Request your Personal Cruise Consultant</td></tr>
            <tr><td style="padding:4px 0;font-size:14px;color:#5a6577;">&#10003;&ensp;Start earning rewards</td></tr>
          </table>
        </td>
      </tr>
    </table>

    <p style="margin:24px 0 0;font-size:13px;color:#b8c0cc;line-height:1.5;word-break:break-all;">Or copy this link: <a href="${setPasswordUrl}" style="color:#0f559a;">${setPasswordUrl}</a></p>
  `)

  return {
    subject: `Welcome to Cruzy+, ${firstName}! Set up your portal access`,
    html,
  }
}

export async function sendEmail(to: string, subject: string, html: string) {
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
    console.warn(`[EMAIL SKIPPED] SMTP not configured. Would have sent "${subject}" to ${to}`)
    return false
  }
  try {
    await transporter.sendMail({ from: FROM, to, subject, html })
    console.log(`[EMAIL SENT] "${subject}" → ${to}`)
    return true
  } catch (err) {
    console.error(`[EMAIL FAILED] "${subject}" → ${to}:`, err)
    return false
  }
}

import { Resend } from 'resend';

const resend = process.env.RESEND_API_KEY ? new Resend(process.env.RESEND_API_KEY) : null;

const PASSWORD_RESET_URL = process.env.PASSWORD_RESET_URL || 'https://roadtrip.app/reset-password';

export async function sendPasswordResetEmail(email, token) {
  if (!resend) {
    console.warn('RESEND_API_KEY not configured - email not sent');
    console.log(`Password reset link would be: ${PASSWORD_RESET_URL}?token=${token}`);
    return { success: false, error: 'Email service not configured' };
  }

  const resetLink = `${PASSWORD_RESET_URL}?token=${token}`;

  try {
    const { data, error } = await resend.emails.send({
      from: 'Roadtrip <noreply@roadtrip.app>',
      to: [email],
      subject: 'Reset your Roadtrip password',
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h1 style="color: #333; font-size: 24px; margin-bottom: 20px;">Reset Your Password</h1>

          <p style="color: #555; font-size: 16px; line-height: 1.5;">
            We received a request to reset your Roadtrip password. Click the button below to create a new password.
          </p>

          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetLink}"
               style="background-color: #007AFF; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: 600; display: inline-block;">
              Reset Password
            </a>
          </div>

          <p style="color: #888; font-size: 14px; line-height: 1.5;">
            This link will expire in <strong>1 hour</strong>. If you didn't request a password reset, you can safely ignore this email.
          </p>

          <p style="color: #888; font-size: 14px; line-height: 1.5;">
            If the button doesn't work, copy and paste this link into your browser:<br>
            <a href="${resetLink}" style="color: #007AFF; word-break: break-all;">${resetLink}</a>
          </p>

          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">

          <p style="color: #999; font-size: 12px;">
            Roadtrip - Your AI Voice Copilot
          </p>
        </div>
      `,
      text: `Reset Your Roadtrip Password

We received a request to reset your password. Visit this link to create a new password:

${resetLink}

This link will expire in 1 hour. If you didn't request a password reset, you can safely ignore this email.

- Roadtrip`
    });

    if (error) {
      console.error('Failed to send password reset email:', error);
      return { success: false, error: error.message };
    }

    console.log(`Password reset email sent to ${email}, id: ${data?.id}`);
    return { success: true, id: data?.id };
  } catch (error) {
    console.error('Error sending password reset email:', error);
    return { success: false, error: error.message };
  }
}

export default {
  sendPasswordResetEmail
};

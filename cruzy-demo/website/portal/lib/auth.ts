import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import crypto from 'crypto'

const JWT_SECRET = process.env.JWT_SECRET || 'cruzy-demo-secret-change-in-prod'

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12)
}

function verifySha256(password: string, storedHash: string): boolean {
  const sha = crypto.createHash('sha256').update(password).digest('hex')
  return storedHash === `sha256:${sha}`
}

/**
 * Returns { valid, needsUpgrade } — when needsUpgrade is true the caller
 * should re-hash with bcrypt and write back to Salesforce.
 */
export async function verifyPassword(
  password: string,
  hash: string
): Promise<{ valid: boolean; needsUpgrade: boolean }> {
  if (hash.startsWith('sha256:')) {
    const valid = verifySha256(password, hash)
    return { valid, needsUpgrade: valid }
  }
  const valid = await bcrypt.compare(password, hash)
  return { valid, needsUpgrade: false }
}

export function generateToken(contactId: string, email: string): string {
  return jwt.sign({ contactId, email }, JWT_SECRET, { expiresIn: '7d' })
}

export function verifyToken(token: string): { contactId: string; email: string } | null {
  try {
    return jwt.verify(token, JWT_SECRET) as { contactId: string; email: string }
  } catch {
    return null
  }
}

export function generateResetToken(): string {
  return crypto.randomBytes(32).toString('hex')
}

export function getResetExpiry(): string {
  const expiry = new Date()
  expiry.setHours(expiry.getHours() + 1)
  return expiry.toISOString()
}

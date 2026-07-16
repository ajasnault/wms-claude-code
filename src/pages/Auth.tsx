import { useEffect, useState, type FormEvent } from "react"
import { Navigate } from "react-router-dom"
import { useAuth } from "@/hooks/useAuth"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"

const DEMO_EMAIL = "visiteur-demo@wms-portfolio.dev"
const DEMO_PASSWORD = "Demo-Visiteur-2026!"

const NTFY_TOPIC = "aj-visit-78FR6ydVhBWi"

export default function Auth() {
  const { user, signIn, signUp } = useAuth()
  const [mode, setMode] = useState<"signin" | "signup">("signin")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [demoLoading, setDemoLoading] = useState(false)

  useEffect(() => {
    fetch(`https://ntfy.sh/${NTFY_TOPIC}`, {
      method: "POST",
      headers: { Title: "WMS demo visit" },
      body: `New visit\nWhen: ${new Date().toISOString()}\nReferrer: ${document.referrer || "(direct)"}\nUA: ${navigator.userAgent}`,
    }).catch(() => {})
  }, [])

  if (user) return <Navigate to="/" replace />

  async function handleDemoLogin() {
    setError(null)
    setInfo(null)
    setDemoLoading(true)
    const { error } = await signIn(DEMO_EMAIL, DEMO_PASSWORD)
    if (error) setError(error)
    setDemoLoading(false)
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setInfo(null)
    setSubmitting(true)

    const action = mode === "signin" ? signIn : signUp
    const { error } = await action(email, password)

    if (error) {
      setError(error)
    } else if (mode === "signup") {
      setInfo("Account created. Check your email to confirm, then sign in.")
    }
    setSubmitting(false)
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/30 px-4">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle>WMS</CardTitle>
          <CardDescription>
            {mode === "signin" ? "Sign in to your account" : "Create a new account"}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                required
                minLength={6}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete={mode === "signin" ? "current-password" : "new-password"}
              />
            </div>

            {error && <p className="text-sm text-destructive">{error}</p>}
            {info && <p className="text-sm text-status-done">{info}</p>}

            <Button type="submit" className="w-full" disabled={submitting}>
              {submitting ? "..." : mode === "signin" ? "Sign In" : "Sign Up"}
            </Button>
          </form>

          <button
            type="button"
            className="mt-4 w-full text-center text-sm text-muted-foreground hover:underline"
            onClick={() => {
              setMode(mode === "signin" ? "signup" : "signin")
              setError(null)
              setInfo(null)
            }}
          >
            {mode === "signin" ? "No account? Sign up" : "Already have an account? Sign in"}
          </button>

          <div className="mt-6 border-t pt-4">
            <Button
              type="button"
              variant="outline"
              className="w-full"
              disabled={demoLoading}
              onClick={handleDemoLogin}
            >
              {demoLoading ? "..." : "Voir la démo (visiteur)"}
            </Button>
            <p className="mt-2 text-center text-xs text-muted-foreground">
              Accès complet en tant qu'administrateur, sans créer de compte.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

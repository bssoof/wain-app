"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword } from "firebase/auth";
import Link from "next/link";
import { auth } from "@/lib/firebase/client";
import { resolveAdminNextPath } from "@/lib/auth/redirect-path";

export default function AdminSignInPage() {
  const router = useRouter();
  const [nextPath, setNextPath] = useState("/admin/dashboard");

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    setNextPath(resolveAdminNextPath(params.get("next"), "/admin/dashboard"));
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const idToken = await userCredential.user.getIdToken();

      const response = await fetch("/api/admin/session", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ idToken }),
      });

      const result = (await response.json()) as {
        success?: boolean;
        error?: string;
      };

      if (response.ok && result.success) {
        router.push(nextPath);
        router.refresh(); // Refresh to catch new cookies in layouts
      } else {
        setError(
          result.error === "Failed to create session"
            ? "تم تسجيل الدخول، لكن تعذر فتح جلسة الإدارة. حاول مرة ثانية."
            : "تعذر تسجيل الدخول. تأكد من البريد وكلمة المرور.",
        );
      }
    } catch (err: any) {
      console.error(err);
      const code = typeof err?.code === "string" ? err.code : "";
      if (code === "auth/network-request-failed") {
        setError("ما قدرنا نتصل بالخدمة. تأكد من الإنترنت وحاول مرة ثانية.");
      } else if (code === "auth/invalid-credential") {
        setError("البريد أو كلمة المرور غير صحيحة.");
      } else if (code === "auth/invalid-api-key") {
        setError("خدمة تسجيل الدخول غير جاهزة الآن. تواصل مع المسؤول.");
      } else if (code === "auth/operation-not-allowed") {
        setError("خدمة تسجيل الدخول غير مفعلة الآن. تواصل مع المسؤول.");
      } else if (code === "auth/too-many-requests") {
        setError("المحاولات كثيرة. انتظر قليلاً ثم حاول مرة ثانية.");
      } else {
        setError("البريد الإلكتروني أو كلمة المرور غير صحيحة.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="auth-page" dir="rtl" lang="ar">
      <section className="auth-card card auth-signin-card">
        <header className="auth-card-header">
          <h1>تسجيل دخول الإدارة</h1>
          <p>ادخل بياناتك للمتابعة إلى لوحة الإدارة.</p>
        </header>

        {error ? (
          <div className="auth-alert" role="alert" aria-live="polite">
            {error}
          </div>
        ) : null}

        <form onSubmit={handleSubmit} className="auth-form">
          <label className="auth-field" htmlFor="email">
            <span>البريد الإلكتروني</span>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={loading}
              className="auth-input"
              autoComplete="email"
              placeholder="أدخل بريدك الإلكتروني"
            />
          </label>

          <label className="auth-field" htmlFor="password">
            <span>كلمة المرور</span>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={loading}
              className="auth-input"
              autoComplete="current-password"
              placeholder="اكتب كلمة المرور"
            />
          </label>

          <button type="submit" disabled={loading} className="auth-submit">
            {loading ? "جارٍ تسجيل الدخول..." : "تسجيل الدخول"}
          </button>
        </form>

        <div className="auth-links">
          <Link href="/admin/access-denied">عرض حالة رفض الوصول</Link>
        </div>
      </section>
    </main>
  );
}

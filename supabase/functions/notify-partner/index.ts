import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

serve(async (req: Request) => {
  try {
    const payload = await req.json()

    // We only care about inserts on 'drawings'
    if (payload.type !== 'INSERT' || payload.table !== 'drawings') {
      return new Response("Not a drawing insert", { status: 200 })
    }

    const drawing = payload.record
    const recipientId = drawing.recipient_id

    // Initialize Supabase client with Auth Admin context
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Get the recipient's push_token
    const { data: profile, error } = await supabaseClient
      .from('profiles')
      .select('push_token')
      .eq('id', recipientId)
      .single()

    if (error || !profile?.push_token) {
      console.log('No push token found for user or error fetching profile:', error)
      return new Response("No token", { status: 200 })
    }

    const fcmToken = profile.push_token

    // Here you would send the FCM request
    const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')
    if (!fcmServerKey) {
      console.log('FCM_SERVER_KEY is not set. Simulation mode: Notifying token:', fcmToken)
      return new Response("Simulated FCM success", { status: 200 })
    }

    const fcmRes = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${fcmServerKey}`,
      },
      body: JSON.stringify({
        to: fcmToken,
        notification: {
          title: "Novo desenho!",
          body: "Seu amor enviou um novo desenho para você ❤️",
          sound: "default",
        },
        data: {
          drawingId: drawing.id,
          type: "new_drawing"
        }
      }),
    })

    const fcmData = await fcmRes.json()
    console.log('FCM response:', fcmData)

    return new Response(JSON.stringify(fcmData), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    })

  } catch (error) {
    console.error('Error serving function:', error)
    return new Response(String(error?.message), { status: 500 })
  }
})

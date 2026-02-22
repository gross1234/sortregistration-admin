# Sort App Admin Dashboard

## Setup

Before using the admin dashboard, you need to create the `properties` table in your Supabase database.

### Option 1: Supabase Dashboard (Recommended)

1. Go to your [Supabase SQL Editor](https://supabase.com/dashboard/project/tjnlzdrxhivnbgssvqqy/sql)
2. Click "New query"
3. Copy and paste the contents of `setup.sql`
4. Click "Run"

### Option 2: Supabase CLI

```bash
supabase login
supabase link --project-ref tjnlzdrxhivnbgssvqqy
supabase db push
```

## Running the Dashboard

Simply open `index.html` in your browser:

```bash
open admin/index.html
```

## Features

- **View Statistics**: Total apartments, residents, events, and attendance
- **Manage Apartments**: Add, view, and delete properties
- **View Residents**: See all residents, search by name/email/building
- **View Events**: See all events with attendance counts

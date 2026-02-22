-- Properties/Apartments table for admin management
CREATE TABLE IF NOT EXISTS properties (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    image_url TEXT,
    description TEXT,
    amenities TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read properties
CREATE POLICY "Properties are viewable by everyone"
ON properties FOR SELECT
USING (true);

-- Allow service role to manage properties
CREATE POLICY "Service role can manage properties"
ON properties FOR ALL
USING (auth.role() = 'service_role');

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_properties_name ON properties(name);

-- View to get resident counts per property
CREATE OR REPLACE VIEW property_stats AS
SELECT
    p.id,
    p.name,
    p.address,
    p.city,
    p.state,
    COUNT(DISTINCT u.id) as resident_count,
    COUNT(DISTINCT e.id) as event_count
FROM properties p
LEFT JOIN users u ON u.building_name = p.name
LEFT JOIN events e ON e.location ILIKE '%' || p.name || '%'
GROUP BY p.id, p.name, p.address, p.city, p.state;

-- Daily polls table (created by super admin)
CREATE TABLE IF NOT EXISTS daily_polls (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    question TEXT NOT NULL,
    options JSONB NOT NULL DEFAULT '[]',
    active_date DATE NOT NULL,
    building_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE daily_polls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Polls are viewable by everyone"
ON daily_polls FOR SELECT
USING (true);

CREATE POLICY "Service role can manage polls"
ON daily_polls FOR ALL
USING (auth.role() = 'service_role');

CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_polls_date ON daily_polls(active_date);

-- Poll votes table
CREATE TABLE IF NOT EXISTS poll_votes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    poll_id UUID NOT NULL REFERENCES daily_polls(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    selected_option INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(poll_id, user_id)
);

ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all votes"
ON poll_votes FOR SELECT
USING (true);

CREATE POLICY "Users can insert their own votes"
ON poll_votes FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_poll_votes_poll ON poll_votes(poll_id);

-- Vote likes table (upvotes on poll answers)
CREATE TABLE IF NOT EXISTS vote_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vote_id UUID NOT NULL REFERENCES poll_votes(id) ON DELETE CASCADE,
    poll_id UUID NOT NULL REFERENCES daily_polls(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vote_id, user_id)
);

ALTER TABLE vote_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all vote likes"
ON vote_likes FOR SELECT
USING (true);

CREATE POLICY "Users can insert their own likes"
ON vote_likes FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own likes"
ON vote_likes FOR DELETE
USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_vote_likes_vote ON vote_likes(vote_id);
CREATE INDEX IF NOT EXISTS idx_vote_likes_poll ON vote_likes(poll_id);

-- Question submissions from users
CREATE TABLE IF NOT EXISTS question_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, approved, rejected
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE question_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own submissions"
ON question_submissions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own submissions"
ON question_submissions FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role can manage submissions"
ON question_submissions FOR ALL
USING (auth.role() = 'service_role');

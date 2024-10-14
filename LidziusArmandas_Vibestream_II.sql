/*
Question #1:

Vibestream is designed for users to share brief updates about how they are feeling, as such the
platform enforces a character limit of 25. How many posts are exactly 25 characters long?

Expected column names: char_limit_posts
*/

-- Q1 solution:

--We want a count of posts that are exactly 25 character length.

SELECT COUNT(post_id) AS char_limit_posts   -- Counting all posts and renaming the column
FROM posts																	-- Selecting from 'posts' table
WHERE length(content) = 25									-- Filtering out only posts that are 25 character length
;


/*
Question #2:

Users JamesTiger8285 and RobertMermaid7605 are Vibestream’s most active posters.

Find the difference in the number of posts these two users made on each day that at least one of them
made a post. Return dates where the absolute value of the difference between posts made is greater
than 2 (i.e dates where JamesTiger8285 made at least 3 more posts than RobertMermaid7605 or vice versa).

**Expected column names: `post_date`**
*/

-- Q2 solution:

-- Firstly we want to find how many posts were made per date (if any of the user made a post) by the given users
-- Secondly we want filter out the post dates by the given criteria: that one of user made at least 3 more posts

WITH tempt AS																										 -- Creating a temp table to count each users' posts
(
SELECT posts.post_date																					 -- Post date for a given user
       ,SUM(CASE WHEN users.user_name = 'JamesTiger8285' THEN 1 ELSE 0 END) AS james_posts					-- Post count first user
       ,SUM(CASE WHEN users.user_name = 'RobertMermaid7605' THEN 1 ELSE 0 END) AS robert_posts			-- Post count second user
FROM posts
JOIN users																											 -- Joining 'posts' and 'users' tables (because user_id is not known)
ON posts.user_id = users.user_id
WHERE users.user_name IN ('JamesTiger8285', 'RobertMermaid7605') -- Filtering dates and post counts by the two users
GROUP BY posts.post_date																				 -- Grouping post counts by date
)

SELECT post_date																								 -- Selecting final dates
FROM tempt																											 -- from temp table
WHERE ABS(james_posts - robert_posts) > 2												 -- Filtering post counts that the difference is more than 2 posts per date
ORDER BY post_date																							 -- Ordering post date ascending
;


/*
Question #3:

Most users have relatively low engagement and few connections. User WilliamEagle6815, for example, has only
2 followers.

Network Analysts would say this user has two **1-step path** relationships. Having 2 followers doesn’t mean
WilliamEagle6815 is isolated, however. Through his followers, he is indirectly connected to the larger
Vibestream network.  

Consider all users up to 3 steps away from this user:

- 1-step path (X → WilliamEagle6815)
- 2-step path (Y → X → WilliamEagle6815)
- 3-step path (Z → Y → X → WilliamEagle6815)

Write a query to find follower_id of all users within 4 steps of WilliamEagle6815. Order by follower_id and
return the top 10 records.

Expected column names: `follower_id`
*/

-- Q3 solution:

SELECT follower_id																							-- 1-step path
FROM users																											-- We find follower_ids who follow WilliamEagle6815 directly
JOIN follows
ON users.user_id = follows.followee_id
WHERE user_name = 'WilliamEagle6815'

UNION																														-- UNION to add only unique (distinct) values

SELECT follower_id																							-- 2-step path
FROM users											
JOIN follows
ON users.user_id = follows.followee_id
WHERE followee_id IN(SELECT follower_id													-- Adding 1-step path results into subquary to find 2-step path records
										 FROM users
										 JOIN follows
										 ON users.user_id = follows.followee_id
										 WHERE user_name = 'WilliamEagle6815')
                     
UNION

SELECT follower_id																							-- 3-step path
FROM users
JOIN follows
ON users.user_id = follows.followee_id
WHERE followee_id IN(SELECT follower_id													-- Adding 2-step path results into subquary to find 3-step path records
                      FROM users
                      JOIN follows
                      ON users.user_id = follows.followee_id
                      WHERE followee_id IN(SELECT follower_id
                                           FROM users
                                           JOIN follows
                                           ON users.user_id = follows.followee_id
                                           WHERE user_name = 'WilliamEagle6815'))
                                           
UNION

SELECT DISTINCT follower_id																			-- 4-step path
FROM users
JOIN follows
ON users.user_id = follows.followee_id
WHERE followee_id IN(SELECT follower_id													-- Adding 3-step path results into subquary to find 4-step path records
										 FROM users
										 JOIN follows
										 ON users.user_id = follows.followee_id
										 WHERE followee_id IN(SELECT follower_id
                                          FROM users
                                          JOIN follows
                                          ON users.user_id = follows.followee_id
                                          WHERE followee_id IN(SELECT follower_id
                                                               FROM users
                                                               JOIN follows
                                                               ON users.user_id = follows.followee_id
                                                               WHERE user_name = 'WilliamEagle6815')))
AND follower_id != (SELECT user_id	-- Adding a filter, to make sure that user would not be included in the list while following himself
                    FROM users
                    WHERE user_name = 'WilliamEagle6815')
ORDER BY 1																											-- Order the list by follower_id
LIMIT 10																												-- Showing only the top 10 records (Total 363 records)
;


/*
Question #4:

Return **top posters** for 2023-11-30 and 2023-12-01. A **top poster** is a user who has the most OR second
most number of posts in a given day. Include the number of posts in the result and order the result by
post_date and user_id.

Expected column names: `post_date`, `user_id`, `posts`
*/

-- Q4 solution:

WITH tempt AS																										-- Temporary table using CTE (Common Table Expression)
(																																-- to rank all the users by posts
SELECT post_date																								-- Selecting all the rows that will be necessary at the final query
			 ,user_id
       ,COUNT(post_id) AS posts
       ,DENSE_RANK() OVER (PARTITION BY post_date ORDER BY COUNT(post_id) DESC) AS rank  -- Window function to rank all the users
FROM posts
WHERE post_date = '2023-11-30'																	-- Filtering records for the specific dates
OR post_date = '2023-12-01'
GROUP BY 1, 2																										-- Grouping records, because we have aggregated data (posts)
)

SELECT post_date																								-- Selecting final columns
			 ,user_id
       ,posts
FROM tempt																											-- from temporary CTE table
WHERE rank <= 2																									-- Filtering to include only top 1 and top 2 users
ORDER BY 1, 2																										-- Ordering the final table by post_date and user_id
;
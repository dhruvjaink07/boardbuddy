# Analytics Algorithm

This dashboard computes insights for each accessible board and an overall summary, then flags boards needing attention.

## Data Sources
- Boards: owned by the user and boards where the user is a member.
- Tasks: cards inside each board's columns (Todo, In Progress, Done), plus their assignees and checklist state.
- Files and comments: counts aggregated from attachments and comments subcollections.
- Optional: additional metadata (e.g., timestamps) can be used for recency weighting.

## Per‑Board Insight Computation
1. Gather the board's tasks by column and count:
   - total = todo + inProgress + completed
   - completed = tasks in "Done"
   - inProgress = tasks in "In Progress"
   - todo = tasks in "Todo"
2. Team contribution:
   - For each task, increment each assignee's count.
   - Convert to percentages by dividing by total assignments and normalizing to 0–100.
3. Resource usage:
   - avgChecklistCompletion = average percentage of completed checklist items across tasks (0–100).
   - fileUploads = total number of file attachments across tasks.
   - commentsCount = total number of comments across tasks.
4. Project health score (0–100):
   - completionRate = completed / max(1, total)      → weight 0.60
   - engagement = clamp(avgChecklistCompletion/100)  → weight 0.30
   - activity/recency (if available)                 → weight 0.10
   - score = (completionRate*0.60 + engagement*0.30 + recency*0.10) * 100

## Overall Summary
- Sum task counts across boards and recompute derived ratios.
- Average teamContribution by summing raw assignment counts per user and normalizing.
- Sum fileUploads/comments and average avgChecklistCompletion weighted by task counts.

## “Needs Attention” Rule
- A board is flagged if:
  - projectHealthScore < 60, or
  - todoRatio = todo/total > 0.55.
- Boards are sorted by lowest health and the top 5 are displayed with reason tags.
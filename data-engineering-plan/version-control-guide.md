## Version Control Guide for Data Engineering Work

**Why this matters:** Version control isn't just for software engineers. Data engineers need it for SQL queries, pipeline code, dbt models, and data quality tests. At work, you'll collaborate with others and need to track changes to analytics logic.

### Setup (Do this once, at the very beginning)

**Initialize git repo:**

```bash
cd ~/learning
git init
```

**Create `.gitignore`:**

```bash
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
.venv
*.egg-info/
dist/
build/

# Jupyter
.ipynb_checkpoints/
*.ipynb

# Environment files (NEVER commit credentials!)
.env
*.env
.env.local

# Data files (too large for git)
*.parquet
*.csv
*.json
data/raw/
data/transformed/
data/staging/

# Logs
logs/
*.log

# Airflow
airflow/logs/
airflow/*.db
airflow/*.pid
airflow/*.cfg
airflow/webserver_config.py

# Great Expectations
great_expectations/uncommitted/
great_expectations/.ge_store_backend_id

# dbt
dbt_packages/
target/
dbt_modules/
logs/
*.log

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Postgres dumps
*.sql.gz
*.dump
EOF
```

**Make your first commit:**

```bash
git add .gitignore
git add answers/
git add data-engineering-plan/
git commit -m "Initial commit: learning plan and gitignore"
```

---

### Daily Git Workflow

**At the start of each day:**

```bash
# Check status
git status

# See what you've changed since last commit
git diff
```

**After completing homework or exercises:**

```bash
# Add specific files
git add answers/week01/day01/homework.sql
git commit -m "Complete Week 1 Day 1 homework: joins and aggregations"

# Or add all changed files (be careful!)
git add .
git commit -m "Complete Week 1 Day 2: deep dive into joins"
```

**Good commit message patterns for data work:**

```bash
# For SQL homework
git commit -m "Add Week 1 Day 3 exercises: GROUP BY and HAVING"

# For pipeline code
git commit -m "Implement extract_pagila.py with retry logic"
git commit -m "Fix: handle null values in customer transformation"

# For dbt models
git commit -m "Add customer_lifetime_value mart model"
git commit -m "Add data quality tests to staging models"

# For configuration
git commit -m "Update Airflow DAG: add quality check tasks"
git commit -m "Configure GX checkpoint for customer LTV validation"
```

---

### Branching Strategy (Recommended)

As you get more comfortable, use branches for experiments:

```bash
# Create a new branch for a specific feature
git checkout -b week02-window-functions
# ... do your work ...
git add .
git commit -m "Complete window functions exercises"

# Switch back to main
git checkout main

# Merge your work
git merge week02-window-functions

# Delete the feature branch
git branch -d week02-window-functions
```

**When to use branches:**

- **Experimenting with new approaches:** Try a different transformation logic without breaking your working code
- **Working on different weeks in parallel:** One branch per week if you want to jump around
- **Capstone project:** Create a `capstone` branch for your final project

---

### What to Commit (and What NOT to Commit)

**✓ DO commit:**

- All SQL files (homework, queries, DDL)
- Python scripts (extract, transform, load, quality checks)
- dbt models and tests
- Airflow DAGs
- Great Expectations suite configurations
- Documentation (markdown files, README)
- Configuration files (without secrets!)
- Small sample data files (< 1 MB) for testing

**✗ DON'T commit:**

- **Credentials or secrets** (.env files, passwords, API keys)
- **Large data files** (CSV, Parquet, JSON > 1 MB)
- **Logs** (these are generated, not source code)
- **Build artifacts** (dbt target/, Python **pycache**)
- **IDE settings** (unless you want to share them)

**If you accidentally commit a secret:**

```bash
# Remove file from git but keep it locally
git rm --cached .env
git commit -m "Remove .env from version control"

# Add to .gitignore to prevent recommitting
echo ".env" >> .gitignore
git add .gitignore
git commit -m "Add .env to gitignore"
```

**Note:** If you pushed the secret to a remote (GitHub), you need to rotate the credential immediately!

---

### Using GitHub (Optional but Recommended)

**Why use GitHub:**

- Backup your work
- Show your portfolio to your team/manager
- Practice collaboration workflows
- Enable CI/CD for data quality tests

**Setup:**

1. Create a GitHub account (free)
2. Create a new repository called `data-engineering-learning`
3. Set it to **private** if your homework contains proprietary business logic

**Push your work:**

```bash
# Add GitHub as remote
git remote add origin https://github.com/your-username/data-engineering-learning.git

# Push your work
git branch -M main
git push -u origin main

# For subsequent pushes
git push
```

**Good practices for GitHub:**

- Use a descriptive README (your `data-engineering-plan/README.md` is great!)
- Organize your repo with clear folder structure
- Add comments to your SQL and Python code
- Create a `PORTFOLIO.md` highlighting your best work

---

### Weekly Git Checklist

**End of each week, do this:**

```bash
# Review what you've done this week
git log --oneline --since="1 week ago"

# Make sure everything is committed
git status

# If you're using GitHub, push your work
git push

# Tag major milestones
git tag -a week01-complete -m "Completed Week 1: ANSI SQL fundamentals"
git push --tags
```

---

### Advanced: Commit Often, Push Strategically

**Good habit:**

```bash
# Commit after each exercise or significant change
git commit -m "Add exercise 1: film-language join"
git commit -m "Add exercise 2: film-category join"
git commit -m "Add exercise 3: customer-store join"
```

This gives you granular history and makes it easy to undo specific changes.

**When working on complex problems:**

```bash
# Save work in progress even if not complete
git add difficult_query.sql
git commit -m "WIP: customer cohort analysis (not working yet)"

# Continue working...
git add difficult_query.sql
git commit -m "Fix: correct cohort grouping logic"
```

---

### Git Commands Cheat Sheet

```bash
# Status and history
git status                    # What's changed?
git log --oneline            # Commit history
git diff                     # What changed since last commit?
git diff HEAD~1              # Compare to previous commit

# Adding and committing
git add filename.sql         # Stage specific file
git add .                    # Stage all changes
git commit -m "message"      # Commit with message
git commit --amend           # Edit last commit message

# Branching
git branch                   # List branches
git branch new-branch        # Create branch
git checkout branch-name     # Switch to branch
git checkout -b new-branch   # Create and switch to branch
git merge branch-name        # Merge branch into current

# Undoing changes
git checkout -- filename     # Discard changes in working directory
git reset HEAD filename      # Unstage file
git revert commit-hash       # Create new commit that undoes a commit
git reset --hard HEAD~1      # DANGEROUS: delete last commit

# Remote operations (if using GitHub)
git remote -v                # List remotes
git push                     # Push to remote
git pull                     # Pull from remote
git clone url                # Clone a repository
```

---

### Integration with Your Weekly Work

**Week 1-2 (SQL):**

```bash
git commit -m "Week 1 Day 1: Basic joins completed"
git commit -m "Week 1 Day 5: Challenge set completed"
```

**Week 2.5 (dbt):**

```bash
git commit -m "Add dbt project structure"
git commit -m "Add staging models: customers, rentals, payments"
git commit -m "Add customer_lifetime_value mart"
git commit -m "Add data quality tests to dbt models"
```

**Week 5 (Pipelines):**

```bash
git commit -m "Implement extract_pagila.py with logging"
git commit -m "Add transform_customer_metrics.py with Polars"
git commit -m "Create Airflow DAG for customer LTV pipeline"
```

**Week 6 (Data Quality):**

```bash
git commit -m "Set up Great Expectations"
git commit -m "Add customer LTV expectation suite"
git commit -m "Integrate GX validation into Airflow"
```

---

### Portfolio Tip

When you complete the capstone (Weeks 7-8), create a clean portfolio branch:

```bash
git checkout -b portfolio
# Clean up any messy code or incomplete experiments
# Add comprehensive README with screenshots
git commit -m "Portfolio-ready: complete data platform design"
```

This branch becomes what you show to your manager or during internal interviews!

---

### Questions to Ask Yourself

1. **Am I committing often enough?**

   - Goal: Commit at least once per day, after each exercise ideally

2. **Are my commit messages clear?**

   - Bad: "update file"
   - Good: "Add GROUP BY exercises with revenue aggregations"

3. **Have I accidentally committed secrets?**

   - Always check `git diff --staged` before committing

4. **Could someone else (or future me) understand this history?**
   - Your git log should tell the story of your learning journey

---

### Next Steps

- [ ] Initialize your git repo **right now** if you haven't
- [ ] Create .gitignore
- [ ] Make your first commit
- [ ] Commit after each day's exercises
- [ ] (Optional) Set up GitHub and push your work
- [ ] Review your git log at the end of each week

**Remember:** Git is a skill just like SQL or Python. The more you use it, the more natural it becomes. Start simple and add complexity as you get comfortable.

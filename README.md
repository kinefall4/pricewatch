# Community Price Watch

An automated price-reporting and monitoring system that tracks price movements, flags significant changes, and publishes results continuously via a cloud-native CI/CD pipeline.

**Live site:** http://pricewatch-kinefall4-534aca22.s3-website-eu-west-1.amazonaws.com  
**Demo: https://youtu.be/AnyGUS1WN3U
**Repository:** https://github.com/kinefall4/pricewatch

---

## Problem

Price volatility especially in essential goods is a concern that affects consumers, community organizations, and small businesses. Existing tools for tracking price changes are either expensive, require manual effort, or are not accessible to non-technical users.

Community Price Watch addresses this by automating the full pipeline from raw price data to a live, publicly accessible report, with no manual intervention required after a data update is committed.

---

## What It Does

- Ingests a structured price dataset (CSV)
- Validates the data and rejects malformed entries
- Calculates price changes between reporting periods
- Generates a dashboard showing:
  - Latest prices per item
  - Top movers (ranked by % change)
  - Shock alerts for changes ≥ 20%
- Automatically rebuilds and redeploys the site on every data update via CI/CD

The core value of the project is the **automation pipeline itself**: a single `git push` triggers the entire chain from raw data to a live, updated public site.

---

## Automation Pipeline

```
CSV data update
    → GitHub push
        → AWS CodeBuild webhook trigger
            → Python validation + JSON generation
                → Hugo static site build
                    → S3 deployment
                        → Live site updated
```

No manual steps are required between data input and published output.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Data processing | Python (pandas) |
| Site generation | Hugo |
| CI/CD | AWS CodeBuild (webhook-triggered) |
| Hosting | Amazon S3 static website hosting |
| Infrastructure | Terraform |
| Prototyping / analysis | Jupyter Notebooks |
| Version control | GitHub |

---

## Repository Structure

```
pricewatch/
├── data/
│   └── prices.csv              # Input price dataset
├── src/
│   ├── validate_data.py        # CSV validation logic
│   └── generate_site_data.py   # JSON generation + shock alert logic
├── site/
│   ├── content/                # Hugo content
│   ├── layouts/                # Hugo templates
│   └── assets/data/            # Generated JSON consumed by Hugo
├── infra/
│   └── main.tf                 # Terraform — S3, CodeBuild, IAM, CloudWatch
├── notebooks/
│   ├── 00_problem_definition.ipynb
│   ├── 01_analysis_and_shocks.ipynb
│   └── 02_evaluation.ipynb
└── buildspec.yml               # AWS CodeBuild build instructions
```

---

## Shock Alert Logic

A price change is flagged as a **shock** when the absolute percentage change between two reporting periods meets or exceeds **20%**. Shocks are surfaced prominently on the dashboard to draw attention to significant movements.

```python
SHOCK_THRESHOLD = 0.20  # 20%
```

---

## Jupyter Notebooks

Three notebooks are included as part of the project's prototyping and evaluation record:

- **00_problem_definition.ipynb** — Problem framing, target users, and rationale for the automation approach
- **01_analysis_and_shocks.ipynb** — Exploratory analysis of the price dataset and development of the shock-detection logic
- **02_evaluation.ipynb** — Assessment of the solution's suitability for the problem, including edge cases and limitations

---

## Running Locally

**Prerequisites:** Python 3.x, Hugo, Git

```bash
# Clone the repo
git clone https://github.com/kinefall4/pricewatch.git
cd pricewatch

# Install Python dependencies
pip install -r requirements.txt

# Validate data and generate JSON
python src/validate_data.py
python src/generate_site_data.py

# Serve the Hugo site locally
cd site
hugo server
```

The site will be available at `http://localhost:1313`.

---

## Deploying with Terraform

**Prerequisites:** Terraform, AWS CLI configured

```bash
cd infra
terraform init
terraform apply
```

This provisions:
- An S3 bucket configured for static website hosting
- A CodeBuild project with GitHub webhook integration
- IAM roles and policies
- CloudWatch logging

Once deployed, any push to the main branch triggers a full rebuild and redeployment automatically.

---

## Project Context

This project was developed as the applied outcome of the Duke University specialization *Building Cloud Computing Solutions at Scale* (Coursera). It follows the specialization's project-driven workflow: identify a practical problem, implement a working cloud-native solution, and publish the results publicly for review.

The project was shared on the Duke/Coursera course discussion forum as part of the specialization's community sharing practice.

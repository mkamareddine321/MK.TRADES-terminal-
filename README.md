# MK.TRADES-terminal-
A Multi-Asset Probabilistic Forecasting &amp; Automated Execution System

#### 📂 Project Overview
MK.TRADES is a proprietary, full-stack quantitative trading infrastructure designed for high-stakes, automated market participation. Built by a Mechanical Engineer with a focus on "Defense-in-Depth" risk management, the system treats market volatility as a stochastic engineering problem rather than a speculative one.

The terminal tracks 13 assets—including Gold (XAUUSD), Nasdaq (NQ), and the S&P 500 (ES)—utilizing high-performance computing to run real-time Monte Carlo simulations.

#### 🧠 The Intelligence Core (Probabilistic Forecasting)
The system moves beyond simple indicators, employing a multi-model stochastic framework:

Forecast Models: Utilizes Geometric Brownian Motion (GBM) for target projection and Merton Jump Diffusion (MJD) to model "Stop-Loss DNA," accounting for price gaps and non-normal distributions.

Regime Detection: A Gaussian Hidden Markov Model (HMM) classifies market states (Calm, Normal, Stressed) to dynamically gate signal eligibility.

Volatility Analysis: Employs GJR-GARCH and EGARCH models for volatility clustering and leverage effect analysis.

GPU Acceleration: Powered by an RTX 5090, the system achieves a 10–50× speedup in Monte Carlo path generation via PyTorch CUDA.

#### 🛡️ "Defense-in-Depth" Risk Architecture
The system is built on the principle that capital preservation is the first priority.

8 Safety Gates: The Auto Executor (Phase 3G) enforces mandatory checks, including daily trade caps, confidence thresholds, and broker lot enforcement.

The Risk Governor: A 5-tier circuit breaker system monitoring Max Daily Loss, Max Allowed Drawdown, and Correlated Exposure Groups (e.g., USD, Metals, Energy).

Mathematical Sizing: Real-time position sizing using the Kelly Criterion, optimized against historical edge and win rates.

#### ⚙️ System Validation & Rigor
Walk-Forward Optimization: Signals are calibrated using a 2-year historical lookback to identify optimal GBM components for each asset.

Incubation Phase: All settings undergo a 1-month monitoring phase to ensure price respects the projected "Cones" before live deployment.

Signal Attribution: The Trade Mapper encodes unique Signal IDs into MT5 comments, enabling 5-minute background reconciliation and slippage analysis.

#### 💻 Tech Stack
Backend: Python (FastAPI), C# (ATAS/MQL5), SQLite, Parquet.

Frontend: React, TradingView Lightweight Charts v5, WebSockets (1Hz Batched Ticks).

Compute: PyTorch CUDA (GPU-Accelerated Simulations).

Infrastructure: 5-Tier Orchestrator (Monthly/Weekly/Daily/Hourly/Minute Tiers).

### About the Developer
Mohamad Kamareddine is a Mechanical Engineer (Lebanese American University) and Process Engineer based in Tripoli, Lebanon. He applies industrial process optimization and statistical analysis to the development of high-performance algorithmic trading systems.

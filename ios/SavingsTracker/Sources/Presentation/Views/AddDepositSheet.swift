import SwiftUI

/// Bottom sheet modal for adding deposits with sanitized inputs and quick denomination chips.
public struct AddDepositSheet: View {

    @ObservedObject public var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String = "1000"
    @State private var selectedBucketId: String = ""
    @State private var noteText: String = ""
    @State private var localError: String? = nil

    public init(viewModel: DashboardViewModel, initialBucketId: String? = nil) {
        self.viewModel = viewModel
        let bId = initialBucketId ?? viewModel.goals.first?.id ?? ""
        self._selectedBucketId = State(initialValue: bId)
    }

    private let quickDenominations: [Decimal] = [500, 1000, 2500, 5000]

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Instantly allocate savings to your dedicated buckets.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)

                    amountSection
                    bucketSection
                    noteSection

                    if let err = localError ?? viewModel.errorMessage {
                        errorBanner(message: err)
                    }

                    confirmButton
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Add Savings Deposit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedBucketId.isEmpty || !viewModel.goals.contains(where: { $0.id == selectedBucketId }) {
                selectedBucketId = viewModel.goals.first?.id ?? ""
            }
        }
    }

    // MARK: - Subviews

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SELECT AMOUNT")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
                .tracking(0.6)

            HStack(spacing: 8) {
                ForEach(quickDenominations, id: \.self) { denom in
                    denominationChip(denom)
                }
            }

            customAmountField
        }
    }

    @ViewBuilder
    private func denominationChip(_ denom: Decimal) -> some View {
        let isSelected = amountText == "\(denom)"
        Button {
            AppTheme.playTapSound()
            amountText = "\(denom)"
            localError = nil
        } label: {
            let symbol = viewModel.metrics.currency.symbol
            let intVal = NSDecimalNumber(decimal: denom).intValue
            Text("+\(symbol)\(intVal)")
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? AppTheme.emerald.opacity(0.2) : Color.white.opacity(0.06))
                .foregroundColor(isSelected ? AppTheme.emeraldLight : .white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? AppTheme.emerald : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    private var customAmountField: some View {
        HStack {
            Text(viewModel.metrics.currency.symbol)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(AppTheme.emeraldLight)

            TextField("Amount", text: $amountText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .onChange(of: amountText) { _, _ in
                    localError = nil
                }
        }
        .padding(14)
        .background(Color.black.opacity(0.35))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var bucketSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ALLOCATE TO BUCKET")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
                .tracking(0.6)

            if viewModel.goals.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppTheme.emeraldLight)
                        .font(.system(size: 16))
                    Text("No buckets created yet. This deposit will automatically create a 'General Savings' bucket.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: 14)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(viewModel.goals) { goal in
                        bucketChip(goal)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bucketChip(_ goal: SavingsGoal) -> some View {
        let isSelected = selectedBucketId == goal.id
        Button {
            AppTheme.playTapSound()
            selectedBucketId = goal.id
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: goal.colorHex))
                    .frame(width: 8, height: 8)

                Text(goal.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? Color.white.opacity(0.14) : Color.white.opacity(0.05))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color(hex: goal.colorHex) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRANSACTION NOTE (OPTIONAL)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
                .tracking(0.6)

            TextField("e.g. Salary savings, Freelance bonus", text: $noteText)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.3))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.roseRed)
                .font(.system(size: 12))
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.roseRed)
        }
    }

    private var confirmButton: some View {
        Button {
            let validation = InputSanitizer.validateAmount(amountText)
            switch validation {
            case .success:
                viewModel.deposit(rawAmount: amountText, bucketId: selectedBucketId, rawNote: noteText)
                dismiss()
            case .failure(let error):
                localError = error.localizedDescription
                AppTheme.triggerNotificationHaptic(type: .error)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Confirm Deposit")
                    .font(.system(size: 15, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppTheme.emerald, AppTheme.emerald.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(18)
            .shadow(color: AppTheme.emerald.opacity(0.4), radius: 10, y: 4)
        }
        .padding(.top, 8)
    }
}

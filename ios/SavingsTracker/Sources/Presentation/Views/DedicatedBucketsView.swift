import SwiftUI

/// Dedicated Savings Buckets and Goals with individual progress meters and full customization.
public struct DedicatedBucketsView: View {

    @ObservedObject public var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Subtitle & Add Bucket Row
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dedicated Funds")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.white)
                            Text("Track allocation and milestones across dedicated funds.")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        Button {
                            AppTheme.playTapSound()
                            viewModel.isCreateBucketModalPresented = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("New")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.emerald.opacity(0.18))
                            .foregroundColor(AppTheme.emeraldLight)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.emerald.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.top, 4)

                    // Bucket Cards
                    ForEach(viewModel.goals) { goal in
                        let isHighlighted = viewModel.highlightedBucketId == goal.id

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: goal.colorHex).opacity(0.18))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color(hex: goal.colorHex).opacity(0.35), lineWidth: 1)
                                            )

                                        Image(systemName: goal.iconName)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(Color(hex: goal.colorHex))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(goal.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(goal.category)
                                            .font(.system(size: 11))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }

                                Spacer()

                                HStack(spacing: 6) {
                                    // Edit Bucket Button
                                    Button {
                                        AppTheme.playTapSound()
                                        viewModel.bucketToEdit = goal
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 11, weight: .bold))
                                            .padding(8)
                                            .background(Color.white.opacity(0.06))
                                            .foregroundColor(AppTheme.textSecondary)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                    }

                                    // Deposit Button
                                    Button {
                                        AppTheme.playTapSound()
                                        viewModel.selectedBucketForModal = goal.id
                                        viewModel.isAddModalPresented = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("Deposit")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.08))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                }
                            }

                            // Saved Amount and Percentage
                            HStack {
                                HStack(spacing: 4) {
                                    Text("Saved:")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(viewModel.metrics.currency.format(amount: goal.current))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                }

                                Spacer()

                                Text("\(goal.progressPercentage)%")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(Color(hex: goal.colorHex))
                                    .monospacedDigit()
                            }

                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(height: 8)

                                    Capsule()
                                        .fill(Color(hex: goal.colorHex))
                                        .frame(
                                            width: geometry.size.width * CGFloat(min(1.0, Double(goal.progressPercentage) / 100.0)),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)

                            // Target and Remaining
                            HStack {
                                Text("Target: \(viewModel.metrics.currency.format(amount: goal.target))")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text("Remaining: \(viewModel.metrics.currency.format(amount: goal.remainingAmount))")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 22, isHighlighted: isHighlighted)
                        .contextMenu {
                            Button {
                                viewModel.selectedBucketForModal = goal.id
                                viewModel.isAddModalPresented = true
                            } label: {
                                Label("Deposit", systemImage: "plus.circle")
                            }

                            Button {
                                viewModel.bucketToEdit = goal
                            } label: {
                                Label("Edit Bucket", systemImage: "pencil")
                            }

                            Divider()

                            Button(role: .destructive) {
                                viewModel.bucketToDelete = goal
                                viewModel.isDeleteConfirmationPresented = true
                            } label: {
                                Label("Delete Bucket", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $viewModel.isCreateBucketModalPresented) {
                BucketEditorSheet(viewModel: viewModel)
            }
            .sheet(item: $viewModel.bucketToEdit) { goal in
                BucketEditorSheet(viewModel: viewModel, editingGoal: goal)
            }
            .alert("Delete Bucket?", isPresented: $viewModel.isDeleteConfirmationPresented) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let goal = viewModel.bucketToDelete {
                        viewModel.deleteBucket(id: goal.id)
                        viewModel.bucketToDelete = nil
                    }
                }
            } message: {
                if let goal = viewModel.bucketToDelete {
                    Text("Are you sure you want to delete '\(goal.name)'? Transactions will be reassigned safely to General Savings.")
                } else {
                    Text("Are you sure you want to delete this bucket?")
                }
            }
        }
    }
}

import SwiftUI

/// Modal sheet for creating new savings buckets or modifying existing ones.
public struct BucketEditorSheet: View {

    @ObservedObject public var viewModel: DashboardViewModel
    public var editingGoal: SavingsGoal?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var selectedCategory: String = "Safety"
    @State private var selectedColorHex: String = "#10B981"
    @State private var selectedIconName: String = "shield.fill"

    @State private var showDeleteAlert: Bool = false

    private let categories = [
        "Safety", "Wealth", "Leisure", "Gadgets", "Life", "Home", "Vehicle", "Custom"
    ]

    private let colorPalette = [
        "#10B981", "#3B82F6", "#06B6D4", "#A855F7",
        "#F59E0B", "#FB7185", "#F97316", "#6366F1"
    ]

    private let iconList = [
        "shield.fill", "chart.line.uptrend.xyaxis", "airplane", "laptopcomputer",
        "car.fill", "house.fill", "graduationcap.fill", "gift.fill",
        "heart.fill", "cross.case.fill", "cart.fill", "banknote.fill", "sparkles"
    ]

    public init(viewModel: DashboardViewModel, editingGoal: SavingsGoal? = nil) {
        self.viewModel = viewModel
        self.editingGoal = editingGoal
    }

    private var isEditMode: Bool {
        editingGoal != nil
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Live Preview Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PREVIEW")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: selectedColorHex).opacity(0.2))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: selectedColorHex).opacity(0.4), lineWidth: 1)
                                    )

                                Image(systemName: selectedIconName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color(hex: selectedColorHex))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(name.isEmpty ? "Bucket Name" : name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text(selectedCategory)
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Target")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)

                                Text("\(viewModel.metrics.currency.symbol)\(targetAmount.isEmpty ? "0" : targetAmount)")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(Color(hex: selectedColorHex))
                                    .monospacedDigit()
                            }
                        }
                        .padding(14)
                        .glassCard(cornerRadius: 18)
                    }

                    // MARK: - Bucket Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BUCKET NAME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        TextField("e.g., House Downpayment", text: $name)
                            .padding(14)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }

                    // MARK: - Target Goal Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TARGET GOAL AMOUNT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        HStack(spacing: 8) {
                            Text(viewModel.metrics.currency.symbol)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.emeraldLight)

                            TextField("e.g. 50000", text: $targetAmount)
                                .keyboardType(.numberPad)
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .bold))
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }

                    // MARK: - Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    let isSelected = selectedCategory == cat
                                    Button {
                                        AppTheme.playTapSound()
                                        selectedCategory = cat
                                    } label: {
                                        Text(cat)
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(isSelected ? Color(hex: selectedColorHex).opacity(0.25) : Color.white.opacity(0.04))
                                            .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(isSelected ? Color(hex: selectedColorHex) : Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - Color Palette
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACCENT COLOR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        HStack(spacing: 12) {
                            ForEach(colorPalette, id: \.self) { hex in
                                let isSelected = selectedColorHex == hex
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                    )
                                    .shadow(color: isSelected ? Color(hex: hex).opacity(0.6) : .clear, radius: 6)
                                    .onTapGesture {
                                        AppTheme.playTapSound()
                                        selectedColorHex = hex
                                    }
                            }
                        }
                    }

                    // MARK: - Icon Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ICON")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                            ForEach(iconList, id: \.self) { icon in
                                let isSelected = selectedIconName == icon
                                Button {
                                    AppTheme.playTapSound()
                                    selectedIconName = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .frame(width: 44, height: 44)
                                        .background(isSelected ? Color(hex: selectedColorHex).opacity(0.25) : Color.white.opacity(0.04))
                                        .foregroundColor(isSelected ? Color(hex: selectedColorHex) : AppTheme.textSecondary)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color(hex: selectedColorHex) : Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    // MARK: - Save Button
                    Button {
                        handleSave()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isEditMode ? "checkmark" : "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text(isEditMode ? "Update Bucket" : "Create Bucket")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: selectedColorHex), Color(hex: selectedColorHex).opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color(hex: selectedColorHex).opacity(0.3), radius: 10)
                    }
                    .padding(.top, 8)

                    // MARK: - Delete Option (in edit mode)
                    if isEditMode {
                        Button {
                            AppTheme.playTapSound()
                            showDeleteAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Delete Bucket")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(AppTheme.roseRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .alert("Delete Bucket?", isPresented: $showDeleteAlert) {
                            Button("Cancel", role: .cancel) {}
                            Button("Delete", role: .destructive) {
                                if let id = editingGoal?.id {
                                    viewModel.deleteBucket(id: id)
                                    dismiss()
                                }
                            }
                        } message: {
                            Text("Any historical deposits for this bucket will be preserved safely under General Savings.")
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(isEditMode ? "Edit Bucket" : "New Bucket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        AppTheme.playTapSound()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if let goal = editingGoal {
                    name = goal.name
                    targetAmount = "\(goal.target)"
                    selectedCategory = goal.category
                    selectedColorHex = goal.colorHex
                    selectedIconName = goal.iconName
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func handleSave() {
        if isEditMode, let id = editingGoal?.id {
            let success = viewModel.updateBucket(
                id: id,
                name: name,
                rawTarget: targetAmount,
                colorHex: selectedColorHex,
                iconName: selectedIconName,
                category: selectedCategory
            )
            if success {
                dismiss()
            }
        } else {
            let success = viewModel.createBucket(
                name: name,
                rawTarget: targetAmount,
                colorHex: selectedColorHex,
                iconName: selectedIconName,
                category: selectedCategory
            )
            if success {
                dismiss()
            }
        }
    }
}

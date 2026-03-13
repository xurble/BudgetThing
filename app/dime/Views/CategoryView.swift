//
//  CategoryView.swift
//  xpenz
//
//  Created by Rafael Soh on 10/5/22.
//

import Combine
import CoreHaptics
import SwiftData
import SwiftUI
import UIKit

enum CategoryViewMode {
    case welcome, settings, transaction
}

struct CategoryView: View {
    var mode: CategoryViewMode
//    @Environment(\.colorScheme) var colorScheme
    @State var income = false

    @State var newCategory = false

    @Query(
        filter: #Predicate<Category> { $0.income == false },
        sort: [SortDescriptor(\Category.order)]
    ) private var expenseCategories: [Category]

    @State var showToast = false
    @State var toastTitle = ""
    @State var toastImage = ""
    @State var positive = false

    var disabled: Bool {
        income == false && expenseCategories.count >= 24
    }

    var body: some View {
        VStack(spacing: 5) {
            CategoryListView(income: $income, mode: mode, showToast: $showToast, toastTitle: $toastTitle, toastImage: $toastImage, positive: $positive)

            HStack {
                Picker("", selection: $income) {
                    Text("Expense")
                        .tag(false)
                    Text("Income")
                        .tag(true)
                }
                .pickerStyle(.segmented)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .labelsHidden()
                .layoutPriority(1)

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "plus")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 14.5, weight: .semibold, design: .rounded))

                    Text("New")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundColor(Color.PrimaryText)
                .padding(6)
                .padding(.horizontal, 4.5)
                .background(Color.SecondaryBackground, in: Capsule())
                .opacity(disabled ? 0.5 : 1)
                .contentShape(Rectangle())
                .onTapGesture {
                    if disabled {
                        showToast = true
                        toastImage = "exclamationmark.triangle.fill"
                        toastTitle = "Limit Exceeded"
                        positive = false
                    } else {
                        newCategory = true
                    }
                }
            }
            .padding(25)
        }
        .sheet(isPresented: $newCategory) {
            NewCategoryAlert(income: $income, bottomSpacers: false)
                .presentationDetents([.height(270)])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.keyboard, edges: .all)
        .liquidGlassBackground()
    }
}

struct CategoryListView: View {
    @Binding var income: Bool
    var mode: CategoryViewMode

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var systemColorScheme
    @EnvironmentObject var dataController: DataController

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var bottomEdge: Double = 15

    @AppStorage("categorySuggestions", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var showSuggestions: Bool = true
    @State var suggestionsToast = false

    @Query private var categories: [Category]

    @State var isEditing = false

    @Query(sort: [SortDescriptor(\Category.order)]) private var allCategories: [Category]

    // delete mode
    @State private var deleteMode = false
    @State private var toDelete: Category?
    var alertMessage: String {
        "Delete '" + (toDelete?.wrappedName ?? "") + "'?"
    }

    // edit mode
    @State private var toEdit: Category?

    // toasts
    @Binding var showToast: Bool
    @Binding var toastTitle: String
    @Binding var toastImage: String
    @Binding var positive: Bool

    var toastColor: Color {
        positive ? Color.IncomeGreen : Color.AlertRed
    }

    var sectionHeader: LocalizedStringKey {
        if income {
            return "INCOME CATEGORIES"
        } else {
            return "EXPENSE CATEGORIES"
        }
    }

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        VStack(spacing: 5) {
            if showToast {
                HStack(spacing: 6.5) {
                    Image(systemName: toastImage)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(toastColor)

                    Text(toastTitle)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .lineLimit(1)
//                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(toastColor)
                }
                .padding(10)
                .toastGlassRoundedRect(tint: toastColor)
                .transition(ToastAnimationStyle.transition)
                .frame(maxWidth: 250)
                .frame(height: 35)
                .padding(20)
            } else {
                if mode == .welcome {
                    HStack(spacing: 8) {
                        if categories.count > 1 {
                            if isEditing {
                                Circle()
                                    .fill(Color.IncomeGreen.opacity(0.23))
                                    .frame(width: 33, height: 33)
                                    .overlay {
                                        Image(systemName: "checkmark")
                                            .font(.system(.callout, design: .rounded).weight(.semibold))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.IncomeGreen)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }
                            } else {
                                Circle()
                                    .fill(Color.SecondaryBackground)
                                    .frame(width: 33, height: 33)
                                    .overlay {
                                        Image(systemName: "arrow.up.arrow.down")
                                            .font(.system(.callout, design: .rounded).weight(.semibold))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                            .foregroundColor(Color.SubtitleText)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }
                            }
                        }

                        Circle()
                            .fill(Color.SecondaryBackground)
                            .frame(width: 33, height: 33)
                            .overlay {
                                Image(systemName: showSuggestions ? "eye.slash" : "eye")
                                    .font(.system(.callout, design: .rounded).weight(.semibold))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                    .foregroundColor(Color.SubtitleText)
                                    .offset(y: 0.8)
                            }
                            .onTapGesture {
                                withAnimation {
                                    showSuggestions.toggle()
                                }
                            }

                        Spacer()

                        Circle()
                            .fill(!allCategories.isEmpty ? Color.IncomeGreen.opacity(0.23) : Color.clear)
                            .frame(width: 33, height: 33)
                            .overlay {
                                ZStack {
                                    Image(systemName: "arrow.right")
                                        .font(.system(.callout, design: .rounded).weight(.semibold))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                        .foregroundColor(!allCategories.isEmpty ? Color.IncomeGreen : Color.Outline.opacity(0.8))

                                    if allCategories.count == 0 {
                                        Circle()
                                            .stroke(Color.Outline.opacity(0.4), lineWidth: 1.3)
                                            .frame(width: 33, height: 33)
                                    }
                                }
                            }
                            .onTapGesture {
                                if allCategories.count > 0 {
                                    dismiss()
                                }
                            }
                    }
                    .frame(height: 35)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Text("Categories")
                            .font(.system(.title3, design: .rounded).weight(.medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 20, weight: .medium, design: .rounded))
                    }
                    .padding(20)

                } else {
                    HStack(spacing: 8) {
                        if mode == .settings {
                            Circle()
                                .fill(Color.SecondaryBackground)
                                .frame(width: 33, height: 33)
                                .overlay {
                                    Image(systemName: "chevron.left")
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color.SubtitleText)
                                        .offset(y: 0.8)
                                }
                                .onTapGesture {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                        } else {
                            Circle()
                                .fill(Color.SecondaryBackground)
                                .frame(width: 33, height: 33)
                                .overlay {
                                    Image(systemName: "chevron.down")
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                        .foregroundColor(Color.SubtitleText)
                                        .offset(y: 0.8)
                                }
                                .onTapGesture {
                                    dismiss()
                                }
                        }

                        Spacer()

                        Circle()
                            .fill(Color.SecondaryBackground)
                            .frame(width: 33, height: 33)
                            .overlay {
                                Image(systemName: showSuggestions ? "eye.slash" : "eye")
                                    .font(.system(.callout, design: .rounded).weight(.semibold))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.SubtitleText)
                                    .offset(y: 0.8)
                            }
                            .onTapGesture {
                                withAnimation {
                                    showSuggestions.toggle()
                                }
                            }

                        if categories.count > 1 {
                            if isEditing {
                                Circle()
                                    .fill(Color.IncomeGreen.opacity(0.23))
                                    .frame(width: 33, height: 33)
                                    .overlay {
                                        Image(systemName: "checkmark")
                                            .font(.system(.callout, design: .rounded).weight(.semibold))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.IncomeGreen)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }
                            } else {
                                Circle()
                                    .fill(Color.SecondaryBackground)
                                    .frame(width: 33, height: 33)
                                    .overlay {
                                        Image(systemName: "arrow.up.arrow.down")
                                            .font(.system(.callout, design: .rounded).weight(.semibold))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color.SubtitleText)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: 35)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Text("Categories")
                            .font(.system(.title3, design: .rounded).weight(mode == .settings ? .semibold : .medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 20, weight: mode == .settings ? .semibold : .medium, design: .rounded))
                    }
                    .padding(20)
                }
            }

            VStack {
                List {
                        Section(header: Text(sectionHeader).foregroundColor(Color.SubtitleText)) {
                            if categories.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "tray")
                                        .font(.system(.largeTitle, design: .rounded).weight(.light))
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                        .font(.system(size: 37, weight: .light))
                                        .foregroundColor(Color.SubtitleText)

                                    Group {
                                        if income {
                                            Text("no_income_categories")
                                        } else {
                                            Text("no_expense_categories")
                                        }
                                    }
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.SubtitleText)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 37)
                                .listRowBackground(Color.SettingsBackground)
                            } else {
                                ForEach(categories) { category in
                                    HStack(spacing: 10) {
                                        Text(category.wrappedEmoji)
                                            .font(.system(.subheadline, design: .rounded))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 15))
                                        Text(category.wrappedName)
                                            .font(.system(.body, design: .rounded))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                            .font(.system(size: 18.5, weight: .regular, design: .rounded))
                                            .lineLimit(1)
                                            .foregroundColor(toDelete == category ? Color.AlertRed : Color.PrimaryText)

                                        Spacer()

                                        if !income {
                                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(Color(hex: category.wrappedColour))
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                    .listRowBackground(Color.SettingsBackground)
                                    .listRowSeparatorTint(Color.Outline)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        toEdit = category
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            toDelete = category
                                        } label: {
                                            Image(systemName: "trash.fill")
                                        }
                                        .tint(Color.AlertRed)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            toEdit = category
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .tint(Color("Yellow"))
                                    }
                                }
                                .onMove(perform: moveItem)
                            }

//                                .onDelete(perform: deleteItem)
                        }

                        if showSuggestions {
                            SuggestedCategoriesView(income: income)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .environment(\.editMode, .constant(self.isEditing ? EditMode.active : EditMode.inactive))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .liquidGlassBackground()
        .animation(ToastAnimationStyle.animation, value: showToast)
        .onChange(of: toDelete) { 
            if toDelete != nil {
                deleteMode = true
            }
        }
        .confirmationDialog(
            "Delete '\(toDelete?.wrappedName ?? "")'?",
            isPresented: $deleteMode,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    if let gonnaDelete = toDelete {
                        modelContext.delete(gonnaDelete)
                    }

                    dataController.save()
                }

                toDelete = nil
                deleteMode = false
            }
            Button("Cancel", role: .cancel) {
                deleteMode = false
            }
        } message: {
            Text("This action cannot be undone, and all \(toDelete?.wrappedName ?? "") transactions would be deleted.")
        }
        .sheet(item: $toEdit, onDismiss: {
            toEdit = nil
        }) { category in
            EditCategoryAlert(toEdit: category, showRootToast: $showToast, rootToastTitle: $toastTitle, rootToastImage: $toastImage, positive: $positive, bottomSpacers: false)
                .presentationDetents([.height(270)])
        }
        .onChange(of: showToast) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .onChange(of: showSuggestions) { _, newValue in
            if !newValue {
                toastTitle = "Suggestions Hidden"
                toastImage = "eye.slash"
                showToast = true
                positive = true
            }
        }
    }

    private func moveItem(at sets: IndexSet, destination: Int) {
        let itemToMove = sets.first!

        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = categories[itemToMove].order
            while startIndex <= endIndex {
                categories[startIndex].order = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            categories[itemToMove].order = startOrder
        } else if destination < itemToMove {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = categories[destination].order + 1
            let newOrder = categories[destination].order
            while startIndex <= endIndex {
                categories[startIndex].order = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            categories[itemToMove].order = newOrder
        }

        dataController.save()
    }

    init(income: Binding<Bool>, mode: CategoryViewMode, showToast: Binding<Bool>, toastTitle: Binding<String>, toastImage: Binding<String>, positive: Binding<Bool>) {
        let isIncome = income.wrappedValue
        _categories = Query(
            filter: #Predicate<Category> { $0.income == isIncome },
            sort: [SortDescriptor(\Category.order)]
        )

        _income = income
        _showToast = showToast
        _toastTitle = toastTitle
        _toastImage = toastImage
        _positive = positive
        self.mode = mode
    }
}

struct NewCategoryAlert: View {
    @Binding var income: Bool
    let budgetMode: Bool
    let bottomSpacers: Bool

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var systemColorScheme
    @EnvironmentObject var dataController: DataController


    // existing categories

    @Query(
        filter: #Predicate<Category> { $0.income == false },
        sort: [SortDescriptor(\Category.order)]
    ) private var expenseCategories: [Category]
    @Query(
        filter: #Predicate<Category> { $0.income == true },
        sort: [SortDescriptor(\Category.order)]
    ) private var incomeCategories: [Category]
    @State private var availableColours: [String] = Color.colorArray

    // state
    @State private var newName = ""
    @State private var newEmoji = ""
    @State private var selectedColour: String = "#FFFFFF"

    @FocusState var focusedField: FocusedField?

    enum FocusedField: Hashable {
        case emoji, name
    }

    // toasts
    @State var outcome = CategoryError.none
    @State var showToast = false
    @State var toastTitle = ""
    @State var toastImage = ""
    @State var positive = false

    var toastColor: Color {
        positive ? Color.IncomeGreen : Color.AlertRed
    }

    var addButtonDisabled: Bool {
        return newName.trimmingCharacters(in: .whitespacesAndNewlines) == "" || newEmoji == ""
    }

    @State var showNativePicker: Bool = false
    @State var customSelectedColor = Color.white

//    @State var isFetching = false

    var body: some View {
        VStack {
            VStack {
                VStack {
                    if showToast {
                        HStack(spacing: 5) {
                            Image(systemName: toastImage)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(toastColor)

                            Text(toastTitle)
                                .font(.system(.callout, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .lineLimit(1)
//                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(toastColor)
                        }
                        .padding(6)
                        .toastGlassRoundedRect(tint: toastColor)
                        .transition(ToastAnimationStyle.transition)
                        .frame(maxWidth: 200)
                    } else {
                        if expenseCategories.count == 24 {
                            Text("Income Category")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .padding(.top, 4)
                        } else if budgetMode {
                            Text("Expense Category")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .padding(.top, 4)
                        } else {
                            Picker("", selection: $income) {
                                Text("Expense")
                                    .tag(false)
                                Text("Income")
                                    .tag(true)
                            }
                            .pickerStyle(.segmented)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            .labelsHidden()
                        }
                    }
                }
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(7)
                            .background(Color.SecondaryBackground, in: Circle())
                            .contentShape(Circle())
                    }
                }

                Spacer()

                ZStack {
                    EmojiTextField(text: $newEmoji)
                        .focused($focusedField, equals: .emoji)
                        .onReceive(Just(newEmoji), perform: { _ in
                            if String(self.newEmoji.onlyEmoji().suffix(1)) != self.newEmoji.onlyEmoji().prefix(1) {
                                self.newEmoji = String(self.newEmoji.onlyEmoji().suffix(1))
                            } else {
                                self.newEmoji = String(self.newEmoji.onlyEmoji().prefix(1))
                            }
                        })
                        .font(.system(size: 160))
                        .padding(8)
                        .frame(width: 80, height: 80, alignment: .center)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(focusedField == .emoji ? Color.SubtitleText : Color.clear, lineWidth: 2.2)
                                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.SecondaryBackground))
                        }

                    if newEmoji == "" {
                        Image("emoji-happy")
                            .resizable()
                            .foregroundColor(Color.PrimaryText)
                            .frame(width: 35, height: 35, alignment: .center)
                            .allowsHitTesting(false)
                    }
                }

                Spacer()

                HStack {
                    if !income {
                        Menu {
                            Picker("Color", selection: $selectedColour) {
                                ForEach(availableColours, id: \.self) { colorHex in
                                    ColorMenuItemView(colorHex: colorHex)
                                        .tag(colorHex)
                                }

                                if !availableColours.contains(selectedColour) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "paintpalette.fill")
                                        Text("Custom")
                                    }
                                    .tag(selectedColour)
                                }
                            }
                            Button("Custom...") {
                                customSelectedColor = Color(hex: selectedColour)
                                showNativePicker = true
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(Color(hex: selectedColour))
                                .padding(8)
                                .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .frame(width: 50, height: 50)
                        }
                    }
//
//                    HStack(spacing: 8) {
//
//
//                        if isFetching {
//                            ProgressView()
//                                .padding(8)
//                        } else if newName != "" {
//                            Image(systemName: "xmark.circle.fill")
//                                .foregroundColor(Color.SubtitleText)
//                                .font(.system(size: 20, weight: .semibold))
//                                .padding(8)
//                                .onTapGesture {
//                                    withAnimation {
//                                        newName = ""
//                                    }
//                                }
//                        }
//                    }
                    NormalTextField(text: $newName, placeholder: "Category Name", action: verification)
                        .focused($focusedField, equals: .name)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .foregroundColor(Color.PrimaryText)

                        .frame(height: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(focusedField == .name ? Color.SubtitleText : Color.clear, lineWidth: 2.2)
                                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.SecondaryBackground))
                        }
                    //
                    Button {
                        verification()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.LightIcon)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 50, height: 50)
                            .background(Color.DarkBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                }
            }
            .padding(13)
            .frame(maxHeight: bottomSpacers ? 350 : .infinity)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .liquidGlassBackground()
        .animation(ToastAnimationStyle.animation, value: showToast)
        .onChange(of: expenseCategories.count) { 
            if expenseCategories.count == 24 {
                dismiss()
            }
        }
        .onChange(of: showToast) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .onChange(of: customSelectedColor) { 
            selectedColour = customSelectedColor.toHex() ?? "#FFFFFF"
        }
        .colorPickerSheet(isPresented: $showNativePicker, selection: $customSelectedColor, supportsAlpha: false, title: "")
        .onAppear {
            if expenseCategories.count == 24 {
                income = true
            }

            if !income {
                expenseCategories.forEach { category in
                    if availableColours.contains(category.wrappedColour) {
                        availableColours.remove(at: availableColours.firstIndex(of: category.wrappedColour) ?? 0)
                    }
                }

                if availableColours.isEmpty {
                    selectedColour = "#FFFFFF"
                } else {
                    selectedColour = availableColours[0]
                }
            }
        }
    }

    func verification() {
        let results = dataController.categoryCheck(name: newName, emoji: newEmoji, income: income)

        outcome = results.error

        if outcome != .none {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            switch outcome {
            case .incomplete:
                toastTitle = "Incomplete Entry"
                toastImage = "questionmark.app"
            case .missingEmoji:
                toastTitle = "Missing Emoji"
                toastImage = "person.fill"

                focusedField = .emoji
            case .missingName:
                toastTitle = "Missing Name"
                toastImage = "character.cursor.ibeam"

                focusedField = .name
            case .duplicate:
                toastTitle = "Duplicate Found"
                toastImage = "externaldrive"
            case .duplicateEmoji:
                toastTitle = "Duplicate Emoji"
                toastImage = "person.fill"

                focusedField = .emoji
            case .duplicateName:
                toastTitle = "Duplicate Name"
                toastImage = "character.cursor.ibeam"

                focusedField = .name
            default:
                return
            }

            positive = false
            showToast = true

        } else {
            toastTitle = "Added \(newName)"

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            if income {
                let category = Category()
                category.name = newName.trimmingCharacters(in: .whitespaces).capitalized
                category.emoji = newEmoji
                category.dateCreated = Date.now
                category.id = UUID()
                category.colour = "IncomeGreen"
                category.order = results.order
                category.income = true
                modelContext.insert(category)
                dataController.save()

                newName = ""
                newEmoji = ""
            } else {
                let category = Category()
                category.name = newName.trimmingCharacters(in: .whitespaces).capitalized
                category.emoji = newEmoji
                category.dateCreated = Date.now
                category.id = UUID()
                category.income = false

                category.colour = selectedColour
                category.order = results.order

                modelContext.insert(category)
                dataController.save()

                newName = ""
                newEmoji = ""

                availableColours = Color.colorArray
                expenseCategories.forEach { category in
                    if availableColours.contains(category.wrappedColour) {
                        availableColours.remove(at: availableColours.firstIndex(of: category.wrappedColour) ?? 0)
                    }
                }

                if availableColours.isEmpty {
                    selectedColour = "#FFFFFF"
                } else {
                    selectedColour = availableColours[0]
                }
            }

            if budgetMode {
                dismiss()
                return
            } else {
                focusedField = .emoji
                toastImage = "checkmark.circle.fill"
                positive = true
                showToast = true
            }
        }
    }

//    func GPTRecommendations(emoji: String, income: Bool) {
//        guard let url = URL(string: "https://api.openai.com/v1/completions") else {
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//
//        let parameters: [String:Any] = ["model":"text-davinci-003", "prompt":"What is the likely transaction category name for a \(income ? "income" : "expense") category with the emoji \(emoji)?", "temperature":0.9]
//
//        // Convert parameters into JSON data
//        let postData = try? JSONSerialization.data(withJSONObject: parameters)
//
//        request.httpBody = postData
//        request.addValue("Bearer \(Constants.openAPIKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        isFetching = true
//
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            DispatchQueue.main.async {
//
//                if let data = data {
//                    let decoder = JSONDecoder()
//
//                    do {
//                        // Decode data using your model structure
//                        let result = try decoder.decode(OpenAICompletionsResponse.self, from: data)
//                        self.newName = result.choices.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
//                        isFetching = false
//                    } catch {
//                        print("Failed to decode JSON")
//                        isFetching = false
//                    }
//                } else if let error = error {
//                    print("HTTP Request Failed \(error.localizedDescription)")
//                    isFetching = false
//                }
//            }
//        }
//
//        task.resume()
//    }

    init(income: Binding<Bool>, bottomSpacers: Bool, budgetMode: Bool = false) {
        _income = income
        self.budgetMode = budgetMode
        self.bottomSpacers = bottomSpacers
    }
}

struct EditCategoryAlert: View {
    let toEdit: Category
    @Binding var showRootToast: Bool
    @Binding var rootToastTitle: String
    @Binding var rootToastImage: String
    @Binding var positive: Bool

    let bottomSpacers: Bool

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var systemColorScheme
    @EnvironmentObject var dataController: DataController


    // existing categories

    @Query(
        filter: #Predicate<Category> { $0.income == false },
        sort: [SortDescriptor(\Category.order)]
    ) private var expenseCategories: [Category]

    // state
    @State private var newName = ""
    @State private var newEmoji = ""
    @State private var availableColours: [String] = Color.colorArray
    @State private var selectedColour: String = "#FFFFFF"

    @FocusState var focusedField: FocusedField?

    enum FocusedField: Hashable {
        case emoji, name
    }

    // toasts
    @State var outcome = CategoryError.none
    @State var showToast = false
    @State var toastTitle = ""
    @State var toastImage = ""

    // delete mode
    @State private var deleteMode = false
    @State private var toDelete: Category?
    var alertMessage: String {
        "Delete '" + (toDelete?.wrappedName ?? "") + "'?"
    }

    @State var showNativePicker: Bool = false
    @State var customSelectedColor = Color.white

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.SubtitleText)
                    .padding(7)
                    .background(Color.SecondaryBackground, in: Circle())
                    .contentShape(Circle())
            }

            Spacer()

            if showToast {
                HStack(spacing: 5) {
                    Image(systemName: toastImage)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.AlertRed)

                    Text(toastTitle)
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .lineLimit(1)
//                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.AlertRed)
                }
                .padding(6)
                .toastGlassRoundedRect(tint: Color.AlertRed)
                .transition(ToastAnimationStyle.transition)
                .frame(maxWidth: 200)
            } else {
                Text(toEdit.income ? "Income" : "Expense")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }

            Spacer()

            Button {
                toDelete = toEdit
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.AlertRed)
                    .padding(7)
                    .background(Color.AlertRed.opacity(0.23), in: Circle())
                    .contentShape(Circle())
            }
        }
        .frame(height: 30)
    }

    private var emojiPickerView: some View {
        ZStack {
            EmojiTextField(text: $newEmoji)
                .focused($focusedField, equals: .emoji)
                .onReceive(Just(newEmoji), perform: { _ in
                    if String(self.newEmoji.onlyEmoji().suffix(1)) != self.newEmoji.onlyEmoji().prefix(1) {
                        self.newEmoji = String(self.newEmoji.onlyEmoji().suffix(1))
                    } else {
                        self.newEmoji = String(self.newEmoji.onlyEmoji().prefix(1))
                    }
                })
                .font(.system(size: 160))
                .padding(8)
                .frame(width: 80, height: 80, alignment: .center)
                .background {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(focusedField == .emoji ? Color.SubtitleText : Color.clear, lineWidth: 2.2)
                        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.SecondaryBackground))
                }

            if newEmoji == "" {
                Image("emoji-happy")
                    .resizable()
                    .foregroundColor(Color.PrimaryText)
                    .frame(width: 35, height: 35, alignment: .center)
                    .allowsHitTesting(false)
            }
        }
    }

    private var nameRowView: some View {
        HStack {
            if !toEdit.income {
                Menu {
                    Picker("Color", selection: $selectedColour) {
                        ForEach(availableColours, id: \.self) { colorHex in
                            ColorMenuItemView(colorHex: colorHex)
                                .tag(colorHex)
                        }

                        if !availableColours.contains(selectedColour) {
                            HStack(spacing: 8) {
                                Image(systemName: "paintpalette.fill")
                                Text("Custom")
                            }
                            .tag(selectedColour)
                        }
                    }
                    Button("Custom...") {
                        customSelectedColor = Color(hex: selectedColour)
                        showNativePicker = true
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color(hex: selectedColour))
                        .padding(8)
                        .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .frame(width: 50, height: 50)
                }
            }

            NormalTextField(text: $newName, placeholder: "Category Name", action: verification)
                .focused($focusedField, equals: .name)
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
                .frame(height: 50)
                .foregroundColor(Color.PrimaryText)
                .background {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(focusedField == .name ? Color.SubtitleText : Color.clear, lineWidth: 2.2)
                        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.SecondaryBackground))
                }

            Button {
                verification()
            } label: {
                Image(systemName: "checkmark")
                    .foregroundColor(Color.LightIcon)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 50, height: 50)
                    .background(Color.DarkBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
    }

    var body: some View {
        VStack {
            VStack {
                headerView

                Spacer()

                emojiPickerView

                Spacer()

                nameRowView
            }
            .padding(13)
            .frame(maxHeight: bottomSpacers ? 350 : .infinity)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .liquidGlassBackground()
        .animation(ToastAnimationStyle.animation, value: showToast)
        .onChange(of: showToast) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .confirmationDialog(
            alertMessage,
            isPresented: Binding(
                get: { toDelete != nil },
                set: { newValue in
                    if !newValue {
                        toDelete = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let categoryToDelete = toDelete {
                    withAnimation {
                        modelContext.delete(categoryToDelete)
                        dataController.save()
                    }
                }

                toDelete = nil
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                toDelete = nil
            }
        } message: {
            Text("This action cannot be undone, and all \(toDelete?.wrappedName ?? "") transactions would be deleted.")
        }
        .onChange(of: expenseCategories.count) { 
            if expenseCategories.count == 24 {
                dismiss()
            }
        }
        .onChange(of: customSelectedColor) { 
            print("changed")
            selectedColour = customSelectedColor.toHex() ?? "#FFFFFF"
        }
        .colorPickerSheet(isPresented: $showNativePicker, selection: $customSelectedColor, supportsAlpha: false, title: "")
        .onAppear {
            newName = toEdit.wrappedName
            newEmoji = toEdit.wrappedEmoji
            selectedColour = toEdit.wrappedColour

            if !toEdit.income {
                availableColours = Color.colorArray
                expenseCategories.forEach { category in
                    if category.id != toEdit.id,
                       availableColours.contains(category.wrappedColour) {
                        availableColours.remove(at: availableColours.firstIndex(of: category.wrappedColour) ?? 0)
                    }
                }
            }
        }
    }

    func verification() {
        let results = dataController.categoryCheckEdit(name: newName, emoji: newEmoji, toEdit: toEdit)

        outcome = results.error

        if outcome != .none {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            switch outcome {
            case .incomplete:
                toastTitle = "Incomplete Entry"
                toastImage = "questionmark.app"
            case .missingEmoji:
                toastTitle = "Missing Emoji"
                toastImage = "person.fill"

                focusedField = .emoji
            case .missingName:
                toastTitle = "Missing Name"
                toastImage = "character.cursor.ibeam"

                focusedField = .name
            case .duplicate:
                toastTitle = "Duplicate Found"
                toastImage = "externaldrive"
            case .duplicateEmoji:
                toastTitle = "Duplicate Emoji"
                toastImage = "person.fill"

                focusedField = .emoji
            case .duplicateName:
                toastTitle = "Duplicate Name"
                toastImage = "character.cursor.ibeam"

                focusedField = .name
            default:
                return
            }

            showToast = true
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            if toEdit.income {
                toEdit.name = newName.trimmingCharacters(in: .whitespaces).capitalized
                toEdit.emoji = newEmoji

                dataController.save()
            } else {
                toEdit.name = newName.trimmingCharacters(in: .whitespaces).capitalized
                toEdit.emoji = newEmoji
                toEdit.colour = selectedColour

                dataController.save()
            }

            rootToastTitle = "Edited \(newName)"
            rootToastImage = "checkmark.circle.fill"
            positive = true
            showRootToast = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dismiss()
            }
        }
    }
}

struct DeleteCategoryAlert: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let toDelete: Category
    @Binding var deleted: Bool
    @Environment(\.colorScheme) var systemColorScheme

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var bottomEdge: Double = 15

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }

            VStack(alignment: .leading, spacing: 1.5) {
                Text("Delete '\(toDelete.wrappedName)'?")
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.PrimaryText)

                Text("This action cannot be undone.")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.SubtitleText)
                    .padding(.bottom, 15)
                    .accessibility(hidden: true)

                Button {
                    deleted = true
                    dismiss()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            modelContext.delete(toDelete)
                            dataController.save()
                        }
                    }

                } label: {
                    Text("Delete")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundColor(.white)
                        .frame(height: 45)
                        .frame(maxWidth: .infinity)
                        .background(Color.AlertRed, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .padding(.bottom, 8)

                Button {
                    withAnimation(.easeOut(duration: 0.7)) {
                        dismiss()
                    }

                } label: {
                    Text("Cancel")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.PrimaryText.opacity(0.9))
                        .frame(height: 45)
                        .frame(maxWidth: .infinity)
                        .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }
            .padding(13)
//            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height < 0 {
                            offset = gesture.translation.height / 3
                        } else {
                            offset = gesture.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 20 {
                            dismiss()
                        } else {
                            withAnimation {
                                offset = 0
                            }
                        }
                    }
            )
//            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
//                .onEnded({ value in
//                    if value.translation.height > 0 {
//                        dismiss()
//                    }
//                }))
            .padding(.horizontal, 17)
            .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
        }
        .edgesIgnoringSafeArea(.all)
        .background(BackgroundBlurView())
    }
}

struct SuggestedCategoriesView: View {
    let income: Bool
    @Query private var categories: [Category]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var dataController: DataController

    var nameArray: [String] {
        var emptyArray = [String]()

        categories.forEach { category in
            emptyArray.append(category.wrappedName)
        }

        return emptyArray
    }

    var emojiArray: [String] {
        var emptyArray = [String]()

        categories.forEach { category in
            emptyArray.append(category.wrappedEmoji)
        }

        return emptyArray
    }

    var suggestions: [SuggestedCategory] {
        var holding = [SuggestedCategory]()

        if income {
            SuggestedCategory.incomes.forEach { category in
                if !nameArray.contains(category.name) && !emojiArray.contains(category.emoji) {
                    holding.append(category)
                }
            }
        } else {
            SuggestedCategory.expenses.forEach { category in
                if !nameArray.contains(category.name) && !emojiArray.contains(category.emoji) {
                    holding.append(category)
                }
            }
        }

        return holding
    }

    @State private var availableColours: [String] = Color.colorArray
    @State private var selectedColour = "1"

    var body: some View {
        if !suggestions.isEmpty {
            Section(header: Text("SUGGESTED").foregroundColor(Color.SubtitleText)) {
                ForEach(suggestions, id: \.self) { category in
                    HStack(spacing: 8) {
                        Text(category.emoji)
//                            .font(.system(size: 15))
                            .font(.system(.subheadline, design: .rounded))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        Text(LocalizedStringKey(category.name))
                            .font(.system(.body, design: .rounded))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 18.5, weight: .regular, design: .rounded))
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "plus")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
//                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(5)
                            .background(Color.SecondaryBackground, in: Circle())
                            .contentShape(Circle())
                    }
                    .padding(.vertical, 5)
                    .foregroundColor(Color.PrimaryText)
                    .listRowBackground(Color.SettingsBackground)
                    .listRowSeparatorTint(Color.Outline)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // double check

                        let (outcome, _) = dataController.categoryCheck(name: category.name, emoji: category.emoji, income: income)

                        if outcome != .none {
                            return
                        }

                        let impactMed = UIImpactFeedbackGenerator(style: .light)
                        impactMed.impactOccurred()

                        if !income {
                            let suggestedCategory = Category()
                            suggestedCategory.name = NSLocalizedString(category.name, comment: "category name")
                            suggestedCategory.emoji = category.emoji
                            suggestedCategory.dateCreated = Date.now
                            suggestedCategory.id = UUID()
                            suggestedCategory.colour = selectedColour
                            suggestedCategory.order = (categories.last?.order ?? 0) + 1
                            suggestedCategory.income = false
                            modelContext.insert(suggestedCategory)
                            dataController.save()

                            availableColours = Color.colorArray
                            categories.forEach { category in
                                if availableColours.contains(category.wrappedColour) {
                                    availableColours.remove(at: availableColours.firstIndex(of: category.wrappedColour) ?? 0)
                                }
                            }

                            if availableColours.isEmpty {
                                selectedColour = "#FFFFFF"
                            } else {
                                selectedColour = availableColours[0]
                            }
                        } else {
                            let suggestedCategory = Category()
                            suggestedCategory.name = NSLocalizedString(category.name, comment: "category name")
                            suggestedCategory.emoji = category.emoji
                            suggestedCategory.dateCreated = Date.now
                            suggestedCategory.id = UUID()
                            suggestedCategory.colour = "#76FBB0"
                            suggestedCategory.order = (categories.last?.order ?? 0) + 1
                            suggestedCategory.income = true
                            modelContext.insert(suggestedCategory)
                            dataController.save()
                        }
                    }
                }
            }
            .onAppear {
                if !income {
                    categories.forEach { category in
                        if availableColours.contains(category.wrappedColour) {
                            availableColours.remove(at: availableColours.firstIndex(of: category.wrappedColour) ?? 0)
                        }
                    }

                    if availableColours.isEmpty {
                        selectedColour = "#FFFFFF"
                    } else {
                        selectedColour = availableColours[0]
                    }
                }
            }
        }
    }

    init(income: Bool) {
        _categories = Query(
            filter: #Predicate<Category> { $0.income == income },
            sort: [SortDescriptor(\Category.order)]
        )

        self.income = income
    }
}

class UIEmojiTextField: UITextField {
    override var textInputMode: UITextInputMode? {
        .activeInputModes.first(where: { $0.primaryLanguage == "emoji" })
    }

    override func caretRect(for _: UITextPosition) -> CGRect {
        return CGRect.zero
    }
}

struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""

    func makeUIView(context: Context) -> UIEmojiTextField {
        let emojiTextField = UIEmojiTextField()
        emojiTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        emojiTextField.placeholder = placeholder
        emojiTextField.text = text
        emojiTextField.delegate = context.coordinator
        emojiTextField.font = UIFont(name: "HelveticaNeue", size: 50)
        emojiTextField.textAlignment = .center
        emojiTextField.endFloatingCursor()
        emojiTextField.becomeFirstResponder()
        return emojiTextField
    }

    func updateUIView(_ uiView: UIEmojiTextField, context _: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextField

        init(parent: EmojiTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.text = textField.text ?? ""
            }
        }
    }
}

struct NormalTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var action: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.placeholder = placeholder
        textField.autocapitalizationType = .words
        textField.text = text
        textField.delegate = context.coordinator

        textField.font = UIFont.roundedSpecial(ofStyle: .title2, weight: .medium, size: 17)
//
//        UIFont.rounded(ofSize: 20, weight: .medium)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context _: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NormalTextField

        init(parent: NormalTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.text = textField.text ?? ""
            }
        }

        func textFieldShouldReturn(_: UITextField) -> Bool {
            parent.action()

            return true
        }
    }
}

struct ColorMenuItemView: View {
    let colorHex: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 12, height: 12)
            Text(colorHex.uppercased())
        }
    }
}

struct ColourPickerView: View {
    var selectedColours: [String]

    @Binding var showMenu: Bool
    @Binding var selectedColour: String

    @Binding var showNativePicker: Bool

    @State var customMode: Bool = false
    @State var customSelectedColor = Color.white

    @State var testing = false
    let columns = [
        GridItem(.fixed(50), spacing: 8),
        GridItem(.fixed(50), spacing: 8),
        GridItem(.fixed(50), spacing: 8),
        GridItem(.fixed(50), spacing: 8),
        GridItem(.fixed(50), spacing: 8),
        GridItem(.fixed(50))
    ]

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var colourScheme: Int = 0

    @Environment(\.colorScheme) var systemColorScheme

    var darkMode: Bool {
        (colourScheme == 0 && systemColorScheme == .dark) || colourScheme == 2
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Color.colorArray, id: \.self) { suggestedColor in
                if suggestedColor == "#" {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .pink]), center: .center))

                        RoundedRectangle(cornerRadius: 8)
                            .fill(darkMode ? Color("AlwaysDarkBackground") : Color("AlwaysLightBackground"))
                            .padding(5)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(customSelectedColor)
                            .padding(10)

                        if customMode {
                            Image(systemName: "checkmark")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(customSelectedColor.luminance() > 0.5 ? Color.black : Color.white)
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.black)
                        }
                    }
                    .frame(width: 50, height: 50, alignment: .center)
                    .onTapGesture {
                        showMenu = false
                        showNativePicker = true
                    }
                } else {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(hex: suggestedColor))
                        .frame(height: 50)
                        .opacity(selectedColours.contains(suggestedColor) ? 0.2 : 1)
                        .onTapGesture {
                            if !selectedColours.contains(suggestedColor) {
                                withAnimation {
                                    selectedColour = suggestedColor
                                    customMode = false
                                    showMenu = false
                                }
                            }
                        }
                        .overlay {
                            if selectedColour == suggestedColor && !customMode {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundColor(Color.black)
                            }
                        }
                }
            }
        }
        .padding(8)
        .frame(width: 352)
        .background(RoundedRectangle(cornerRadius: 11).fill(darkMode ? Color("AlwaysDarkBackground") : Color("AlwaysLightBackground")).shadow(color: darkMode ? Color.clear : Color.gray.opacity(0.25), radius: 6))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(darkMode ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
    }

    init(selectedColor: Binding<String>, showMenu: Binding<Bool>, showNativePicker: Binding<Bool>, toEdit: Category? = nil) {
        _selectedColour = selectedColor
        _showMenu = showMenu
        _showNativePicker = showNativePicker

        if !Color.colorArray.contains(selectedColor.wrappedValue) {
            _customMode = State(initialValue: true)
            _customSelectedColor = State(initialValue: Color(hex: selectedColor.wrappedValue))
        }

        var selectedColours = [String]()

        let dataController = DataController.shared

        let categories = dataController.getAllCategories(income: false)

        categories.forEach { category in
            selectedColours.append(category.wrappedColour)
        }

        if let editted = toEdit {
            if !selectedColours.isEmpty {
                selectedColours.remove(at: selectedColours.firstIndex(of: editted.wrappedColour) ?? 0)
            }
        }

        self.selectedColours = selectedColours
    }
}

struct OpenAICompletionsResponse: Decodable {
    let id: String
    let choices: [OpenAICompletionsOptions]
}

struct OpenAICompletionsOptions: Decodable {
    let text: String
}

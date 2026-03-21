//
//  TransactionView.swift
//  xpenz
//
//  Created by Rafael Soh on 14/5/22.
//

import Combine
import Foundation
import SwiftData
import SwiftUI
import UIKit

struct TransactionView: View {
    @Query(filter: #Predicate<Category> { $0.income == false }) private var expenseCategories: [Category]
    @Query(filter: #Predicate<Category> { $0.income == true }) private var incomeCategories: [Category]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss

    @Environment(\.colorScheme) var colorScheme
    var boldText: Bool {
        UIAccessibility.isBoldTextEnabled
    }

    @AppStorage("topEdge", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var topEdge:
    Double = 20

    @State private var note = ""
    @State var category: Category?
    @State private var date = Date.now
    @State private var repeatType = 0
    @State private var repeatCoefficient = 1
    @State var income = false

    var transactionTypeString: String {
        if income {
            return "Income"
        } else {
            return "Expense"
        }
    }

    @State var showCategoryPicker = false
    @State var showCategorySheet = false

    @AppStorage("currency", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var currency: String = Locale.current.currency?.identifier ?? "USD"
    var currencySymbol: String {
        return Locale.current.localizedCurrencySymbol(forCurrencyCode: currency)!
    }

    @State var showingDatePicker = false
    @State var showingCategoryView = false

    // toasts
    @State var showToast = false
    @State var toastTitle = ""
    @State var toastImage = ""

    // shaking category error
    @State var categoryButtonTextColor = Color.SubtitleText
    @State var categoryButtonBackgroundColor = Color.clear
    @State var categoryButtonOutlineColor = Color.Outline
    @State var shake: Bool = false

    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()

    @AppStorage(
        "firstTransactionViewLaunch", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
    var firstLaunch: Bool = true

    // edit mode
    let toEdit: Transaction?

    // delete mode

    @State var toDelete: Transaction?
    @State var deleteMode = false

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
    var bottomEdge: Double = 15

    let repeatOverlays = ["D", "W", "M"]
    let numberArray = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    var repeatButtonAccessibility: String {
        if repeatType == 1 {
            return "transaction recurs daily, button to edit recurring duration"
        } else if repeatType == 2 {
            return "transaction recurs weekly, button to edit recurring duration"
        } else if repeatType == 3 {
            return "transaction recurs monthly, button to edit recurring duration"
        } else {
            return "button to make transaction recurring"
        }
    }

    var dateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM yyyy"
        return dateFormatter.string(from: date)
    }

    var showTime: Bool {
        let roundedFont = UIFont.rounded(ofSize: fontSize, weight: .semibold)

        let attributes = [NSAttributedString.Key.font: roundedFont]

        let dateSize: CGSize

        if isDateToday(date: date) {
            dateSize = (("Today, " + getDateString(date: date)) as NSString).size(
                withAttributes: attributes)
        } else {
            dateSize = (getDateString(date: date) as NSString).size(withAttributes: attributes)
        }

        let categorySize = (category?.fullName ?? "X Category").size(withAttributes: attributes)
        let timeSize = (getTimeString(date: date) as NSString).size(withAttributes: attributes)

        let screenWidth: CGFloat

        if boldText {
            screenWidth = (UIScreen.main.bounds.width - 200)
        } else {
            screenWidth = (UIScreen.main.bounds.width - 150)
        }

        if (dateSize.width + categorySize.width + timeSize.width) > screenWidth {
            return false
        } else {
            return true
        }
    }

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
    var colourScheme: Int = 0

    @Environment(\.colorScheme) var systemColorScheme

    var darkMode: Bool {
        (colourScheme == 0 && systemColorScheme == .dark) || colourScheme == 2
    }

    var backgroundColor: Color {
        if darkMode {
            return Color("AlwaysDarkBackground")
        } else {
            return Color("AlwaysLightBackground")
        }
    }

    @State var showPicker = false
    @State var animateIcon = false

    @Namespace var animation

    // show recommendations

    @State var textFieldFocused: Bool = false

    @AppStorage(
        "showTransactionRecommendations", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
    var showRecommendations: Bool = false

    var suggestedTransactions: [Transaction] {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard showRecommendations, textFieldFocused, !trimmedNote.isEmpty else {
            return []
        }

        return dataController.getSuggestedNotes(searchQuery: trimmedNote, category: category, income: income)
    }

    var showingNotePicker: Bool {
        return note != "" && toEdit == nil && !suggestedTransactions.isEmpty && textFieldFocused
        && showRecommendations
    }

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var fontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall:
            return 14
        case .small:
            return 15
        case .medium:
            return 16
        case .large:
            return 17
        case .xLarge:
            return 19
        case .xxLarge:
            return 21
        case .xxxLarge:
            return 23
        default:
            return 23
        }
    }

    var widthOfCategoryButton: CGFloat {
        let fontSize = UIFont.getBodyFontSize(dynamicTypeSize: dynamicTypeSize)

        return "Category".widthOfRoundedString(size: fontSize, weight: .semibold) + 50
    }

    var capsuleWidth: CGFloat {
        if dynamicTypeSize > .xLarge {
            return 120
        } else {
            return 100
        }
    }

    @State private var price: Double = 0
    @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
    var numberEntryType: Int = 1
    @State var isEditingDecimal = false
    @State var decimalValuesAssigned: AssignedDecimal = .none
    @State private var priceString: String = "0"

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 8) {
                // income/expense picker
                VStack {
                    if showToast {
                        HStack(spacing: 6.5) {
                            Image(systemName: toastImage)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundColor(Color.AlertRed)

                            Text(toastTitle)
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .lineLimit(1)
                                .foregroundColor(Color.AlertRed)
                        }
                        .padding(8)
                        .toastGlassRoundedRect(tint: Color.AlertRed)
                        .transition(ToastAnimationStyle.transition)
                        .frame(maxWidth: dynamicTypeSize > .xLarge ? 250 : 200)
                    } else {
                        Picker("", selection: $income) {
                            Text("Expense")
                                .tag(false)
                            Text("transaction-view-income-picker")
                                .tag(true)
                        }
                        .pickerStyle(.segmented)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .frame(width: capsuleWidth * 2)
                        .labelsHidden()
                    }
                }
                //                .frame(height: 50, alignment: .top)
                .frame(maxWidth: .infinity)
                .padding(.top, proxy.safeAreaInsets.top)
                .overlay {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                            //                                .font(.system(size: 16, weight: .semibold))
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                                .foregroundColor(Color.SubtitleText)
                                .padding(7)
                                .background(Color.SecondaryBackground, in: Circle())
                                .contentShape(Circle())
                        }

                        Spacer()

                        if toEdit != nil {
                            Button {
                                toDelete = toEdit
                                deleteMode = true

                            } label: {
                                Image(systemName: "trash.fill")
                                //                                    .font(.system(size: 16, weight: .semibold))
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                                    .foregroundColor(Color.AlertRed)
                                    .padding(7)
                                    .background(Color.AlertRed.opacity(0.23), in: Circle())
                                    .contentShape(Circle())
                            }
                            .accessibilityLabel("delete transaction")
                        }

                        Menu {
                            Button("None") {
                                repeatType = 0
                                repeatCoefficient = 1
                            }
                            Button("Daily") {
                                repeatType = 1
                                repeatCoefficient = 1
                            }
                            Button("Weekly") {
                                repeatType = 2
                                repeatCoefficient = 1
                            }
                            Button("Monthly") {
                                repeatType = 3
                                repeatCoefficient = 1
                            }
                            Button("Custom...") {
                                if repeatType == 0 || repeatCoefficient < 2 {
                                    repeatType = 2
                                    repeatCoefficient = 2
                                }
                                showPicker = true
                            }
                        } label: {
                            if repeatType > 0 {
                                Image(systemName: "repeat")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                                //                                    .font(.system(size: 16, weight: .semibold))
                                    .overlay(alignment: .topTrailing) {
                                        Text(repeatOverlays[repeatType - 1])
                                            .font(.system(size: 6, weight: .black, design: .rounded))
                                            .foregroundColor(Color.IncomeGreen)
                                            .frame(width: 10, alignment: .leading)
                                            .offset(x: 5.7, y: 1.5)
                                    }
                                    .foregroundColor(Color.IncomeGreen)
                                    .padding(7)
                                    .background(Color.IncomeGreen.opacity(0.23), in: Circle())
                                    .contentShape(Circle())
                            } else {
                                Image(systemName: "repeat")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.SubtitleText)
                                    .padding(7)
                                    .background(Color.SecondaryBackground, in: Circle())
                                    .contentShape(Circle())
                            }
                        }
                        .accessibilityLabel(repeatButtonAccessibility)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, topEdge)

                VStack(spacing: 8) {
                    NumberPadTextView(price: $price, isEditingDecimal: $isEditingDecimal, decimalValuesAssigned: $decimalValuesAssigned)
                    NoteView(note: $note, focused: $textFieldFocused)
                }
                .frame(minHeight: 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: NumberPad.preferredSpacing) {
                    if showingNotePicker {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestedTransactions, id: \.self) { transaction in
                                    Button {
                                        note = transaction.wrappedNote
                                        withAnimation {
                                            if price == 0 {
                                                price = transaction.wrappedAmount
                                            }
                                            if category == nil {
                                                category = transaction.category
                                            }
                                        }
                                        self.hideKeyboard()
                                    } label: {
                                        HStack(spacing: 3) {
                                            Text(transaction.wrappedNote)
                                                .foregroundStyle(Color.PrimaryText)
                                                .lineLimit(1)
                                                .padding(.vertical, 3.5)
                                                .padding(.horizontal, 7)

                                            Text("\(currencySymbol)\(Int(round(transaction.wrappedAmount)))")
                                                .lineLimit(1)
                                                .foregroundStyle(Color(hex: transaction.wrappedColour))
                                                .padding(.vertical, 3.5)
                                                .padding(.horizontal, 5)
                                                .background(
                                                    Color(hex: transaction.wrappedColour).opacity(0.23),
                                                    in: RoundedRectangle(cornerRadius: 6.5, style: .continuous))
                                        }
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .padding(5)
                                        .background(
                                            Color.SecondaryBackground,
                                            in: RoundedRectangle(cornerRadius: 11.5, style: .continuous))
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 5)
                    } else {
                        HStack(spacing: 8) {
                            HStack(spacing: 7) {
                                Group {
                                    if date < Date.now {
                                        Image(systemName: "calendar")
                                    } else {
                                        Image(systemName: "rays")
                                            .symbolEffect(
                                                .variableColor.iterative.dimInactiveLayers.nonReversing,
                                                options: .repeating, value: animateIcon)
                                    }
                                }
                                .foregroundColor(Color.SubtitleText)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))

                                Group {
                                    if isDateToday(date: date) {
                                        Text("Today, \(getDateString(date: date))")
                                            .lineLimit(1)
                                    } else {
                                        Text(getDateString(date: date))
                                            .lineLimit(1)
                                    }
                                }
                                .font(.system(.body, design: .rounded).weight(.semibold))

                                if showTime {
                                    Spacer()

                                    Text(getTimeString(date: date))
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                }
                            }
                            .foregroundColor(Color.PrimaryText)
                            .padding(.vertical, 8.5)
                            .padding(.horizontal, 10)
                            .animation(.default, value: isDateToday(date: date))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                                    .strokeBorder(Color.Outline, lineWidth: 1.5)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                UIApplication.shared.endEditing()
                                showingDatePicker = true
                            }

                            if (expenseCategories.count == 0 && !income) || (incomeCategories.count == 0 && income) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))

                                    Text("Category")
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .lineLimit(1)
                                }
                                .padding(.vertical, 8.5)
                                .padding(.horizontal, 10)
                                .foregroundColor(categoryButtonTextColor)
                                .glassRoundedRect(
                                    cornerRadius: 11.5,
                                    tint: categoryButtonBackgroundColor
                                )
                                .contentShape(Rectangle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                                        .strokeBorder(categoryButtonOutlineColor, lineWidth: 1.5)
                                )
                                .drawingGroup()
                                .offset(x: shake ? -5 : 0)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showCategorySheet = true
                                }
                            } else {

                                Group {
                                    if showCategoryPicker {
                                        HStack(spacing: 10) {

                                            Text("Close")
                                                .font(.system(.body, design: .rounded).weight(.semibold))
                                                .lineLimit(1)

//                                        Image(systemName: "xmark.circle.fill")
//                                            .font(.system(.footnote, design: .rounded).weight(.bold))
                                        }
                                        .padding(.vertical, 8.5)
                                        .padding(.horizontal, 10)
                                        .frame(width: widthOfCategoryButton)
                                        .foregroundColor(Color.AlertRed)
                                        .glassRoundedRect(
                                            cornerRadius: 11.5,
                                            tint: Color.AlertRed.opacity(0.23)
                                        )
                                    } else {
                                        if let unwrappedCategory = category {
                                            HStack(spacing: 5) {
                                                Text(unwrappedCategory.wrappedEmoji)
                                                    .font(.system(.footnote, design: .rounded).weight(.semibold))

                                                Text(unwrappedCategory.wrappedName)
                                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                                    .lineLimit(1)
                                            }
                                            .padding(.vertical, 8.5)
                                            .padding(.horizontal, 10)
                                            .foregroundColor(Color(hex: unwrappedCategory.wrappedColour))
                                            .glassRoundedRect(
                                                cornerRadius: 11.5,
                                                tint: Color(hex: unwrappedCategory.wrappedColour).opacity(0.35)
                                            )

                                        } else {
                                            HStack(spacing: 5.5) {
                                                Image(systemName: "circle.grid.2x2")
                                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                                    .symbolEffect(
                                                        .bounce.up.byLayer, options: .repeating.speed(0.5),
                                                        value: showCategoryPicker)

                                                Text("Category")
                                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                                    .lineLimit(1)
                                            }
                                            .padding(.vertical, 8.5)
                                            .padding(.horizontal, 10)
                                            .frame(width: widthOfCategoryButton)
                                            .foregroundColor(categoryButtonTextColor)
                                            .glassRoundedRect(
                                                cornerRadius: 11.5,
                                                tint: categoryButtonBackgroundColor
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                                                    .strokeBorder(categoryButtonOutlineColor, lineWidth: 1.5)
                                            )
                                            .drawingGroup()
                                            .offset(x: shake ? -5 : 0)
                                        }
                                    }

                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        showCategoryPicker.toggle()
                                    }

                                }
                            }
                        }
                    }

                    // date and category picker

                    if showCategoryPicker {
                        NewCategoryPickerView(
                            category: $category, showPicker: $showCategoryPicker,
                            showSheet: $showCategorySheet, income: income
                        )
                        .frame(height: NumberPad.preferredHeight + NumberPad.preferredBottomPadding, alignment: .top)
                        .transition(AnyTransition.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        NumberPad(
                            price: $price,
                            category: $category,
                            isEditingDecimal: $isEditingDecimal,
                            decimalValuesAssigned: $decimalValuesAssigned,
                            showingNotePicker: showingNotePicker
                        ) {
                            submit()
                        }
                        .frame(height: NumberPad.preferredHeight, alignment: .top)
                        .padding(.bottom, NumberPad.preferredBottomPadding)
                        .layoutPriority(1)
                        .transition(AnyTransition.move(edge: .leading).combined(with: .opacity))
                    }
                }

            }
            .padding(.horizontal, 17)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .liquidGlassBackground(opacity: 1)
            .onTapGesture {
                self.hideKeyboard()
            }
            .confirmationDialog(
                "Delete Expense?",
                isPresented: $deleteMode,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    withAnimation {
                        if let itemToDelete = toDelete {
                            modelContext.delete(itemToDelete)
                        }
                        dataController.save(context: modelContext)
                    }

                    deleteMode = false
                    toDelete = nil
                    dismiss()
                }
                Button("Cancel", role: .cancel) {
                    deleteMode = false
                    toDelete = nil
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .overlay {
                ZStack(alignment: .bottom) {
                    GeometryReader { _ in
                        EmptyView()
                    }
                    .background(Color.black)
                    .opacity(showingDatePicker ? 0.3 : 0)
                    .onTapGesture {
                        showingDatePicker = false
                    }

                    DatePicker("Date", selection: $date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
                        .padding(17)
                        .onChange(of: dateString) { 

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingDatePicker = false
                            }

                            if date > Date.now {
                                animateIcon = true
                            } else {
                                animateIcon = false
                            }
                        }
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .opacity(showingDatePicker ? 1 : 0)
                .allowsHitTesting(showingDatePicker)
                .animation(.easeOut(duration: 0.25), value: showingDatePicker)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .animation(ToastAnimationStyle.animation, value: showToast)
        .ignoresSafeArea(.keyboard, edges: .all)
        .frame(maxHeight: .infinity)
        .liquidGlassBackground(opacity: 0.95)
        .edgesIgnoringSafeArea(.all)
        .onChange(of: showToast) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .onChange(of: income) { 
            Haptics.impact(.light)
            category = nil
        }
        .onAppear {
            DispatchQueue.main.async {
                if let transaction = toEdit {
                    repeatType = Int(transaction.recurringType)
                    repeatCoefficient = Int(transaction.recurringCoefficient)
                    price = transaction.wrappedAmount

                    if transaction.wrappedAmount.truncatingRemainder(dividingBy: 1) > 0 && numberEntryType == 2 {
                        isEditingDecimal = true
                        decimalValuesAssigned = .second
                    }

                    if transaction.wrappedDate > Date.now {
                        animateIcon = true
                    }
                }
            }
        }
        .sheet(isPresented: $showCategorySheet) {
            CategoryView(mode: .transaction, income: income)
        }
        .sheet(isPresented: $showPicker) {
            CustomRecurringView(
                repeatType: $repeatType, repeatCoefficient: $repeatCoefficient, showPicker: $showPicker
            )
            .presentationDetents([.height(230)])
        }
    }

    func isDateToday(date: Date) -> Bool {
        let calendar = Calendar.current

        return calendar.isDateInToday(date)
    }

    func getDateString(date: Date) -> String {
        let formatter = DateFormatter()

        if isDateToday(date: date) {
            formatter.dateFormat = "d MMM"

            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "E, d MMM"

            return formatter.string(from: date)
        }
    }

    func getTimeString(date: Date) -> String {
        let formatter = DateFormatter()

        formatter.dateFormat = "HH:mm"

        return formatter.string(from: date)
    }

    func toggleFieldColors() {
        if categoryButtonTextColor == Color.AlertRed
            || categoryButtonBackgroundColor == Color.AlertRed.opacity(0.23) {
            withAnimation(.linear) {
                categoryButtonTextColor = Color.SubtitleText
                categoryButtonBackgroundColor = Color.clear
                categoryButtonOutlineColor = Color.Outline
            }
        } else {
            withAnimation(.easeOut(duration: 1.0)) {
                categoryButtonTextColor = Color.AlertRed
                categoryButtonBackgroundColor = Color.AlertRed.opacity(0.23)
                categoryButtonOutlineColor = Color.AlertRed
            }
            withAnimation(.easeInOut(duration: 0.1).repeatCount(5)) {
                shake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    shake = false
                }
                withAnimation(.easeOut(duration: 0.6)) {
                    categoryButtonTextColor = Color.SubtitleText
                    categoryButtonBackgroundColor = Color.clear
                    categoryButtonOutlineColor = Color.Outline
                }
            }
        }

    }

    func submit() {

        if price == 0 && category == nil {
            toastImage = "questionmark.app"
            toastTitle = "Incomplete Entry"
            showToast = true
            toggleFieldColors()

            Haptics.impact(.heavy)

            return
        } else if price == 0 {
            toastImage = "centsign.circle"
            toastTitle = "Missing Amount"
            showToast = true
            Haptics.impact(.heavy)
            return
        } else if category == nil {
            toastImage = "tray"
            toastTitle = "Missing Category"
            showToast = true

            toggleFieldColors()

            Haptics.impact(.heavy)
            return
        }

        Haptics.impact(.light)

        if let editedTransaction = toEdit {
            if note.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                editedTransaction.note = category!.wrappedName
            } else {
                editedTransaction.note = note.trimmingCharacters(in: .whitespaces)
            }

            if let unwrappedCategory = category {
                editedTransaction.category = unwrappedCategory
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    editedTransaction.amount = price
                    editedTransaction.date = date
                    editedTransaction.income = income

                    let calendar = Calendar(identifier: .gregorian)

                    editedTransaction.day =
                    calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) ?? Date.now

                    let dateComponents = calendar.dateComponents([.month, .year], from: date)

                    editedTransaction.month = calendar.date(from: dateComponents) ?? Date.now

                    if repeatType > 0 {
                        editedTransaction.onceRecurring = true
                        editedTransaction.recurringType = Int16(repeatType)
                        editedTransaction.recurringCoefficient = Int16(repeatCoefficient)

                        dataController.updateRecurringTransaction(transaction: editedTransaction)
                    } else {
                        editedTransaction.onceRecurring = false
                        editedTransaction.recurringType = Int16(repeatType)
                        editedTransaction.recurringCoefficient = Int16(repeatCoefficient)
                    }

                    dataController.save(context: modelContext)
                }
            }

            dismiss()

            return
        }

        let transaction = Transaction()

        if note.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            transaction.note = category?.wrappedName ?? ""
        } else {
            transaction.note = note.trimmingCharacters(in: .whitespaces)
        }

        transaction.income = income

        if let unwrappedCategory = category {
            transaction.category = unwrappedCategory
        }

        transaction.amount = price
        transaction.date = date
        transaction.id = UUID()

        let calendar = Calendar(identifier: .gregorian)

        transaction.day = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) ?? Date.now

        let dateComponents = calendar.dateComponents([.month, .year], from: date)

        transaction.month = calendar.date(from: dateComponents) ?? Date.now

        if repeatType > 0 {
            transaction.onceRecurring = true
            transaction.recurringType = Int16(repeatType)
            transaction.recurringCoefficient = Int16(repeatCoefficient)
            dataController.updateRecurringTransaction(transaction: transaction)
        }

        modelContext.insert(transaction)
        dataController.save(context: modelContext)

        dismiss()
    }

    init(toEdit: Transaction? = nil) {
        if let transaction = toEdit {
            _note = State(initialValue: transaction.wrappedNote)

            if let unwrappedCategory = transaction.category {
                _category = State(initialValue: unwrappedCategory)
            }

            _income = State(initialValue: transaction.income)

            _date = State(initialValue: transaction.date)
        }
        self.toEdit = toEdit
    }

    init(category: Category? = nil) {
        if let unwrappedCategory = category {
            _income = State(initialValue: false)
            _category = State(initialValue: unwrappedCategory)
        }

        toEdit = nil
    }
}

struct FilteredSearchNewTransactionView: View {
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)]) private var transactions: [Transaction]

    var searchQuery: String
    var category: Category?

    var body: some View {
        ScrollView(.horizontal) {
            let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            let filtered = transactions.filter { transaction in
                let matchesQuery = transaction.wrappedNote.localizedCaseInsensitiveContains(trimmedQuery)
                let matchesCategory = category == nil ? true : (transaction.category == category)
                return matchesQuery && matchesCategory
            }

            if !filtered.isEmpty {
                HStack {
                    ForEach(filterOutDupes(day: filtered)) { transaction in
                        Text(transaction.wrappedNote)
                    }
                }
            }
        }
    }

    init(searchQuery: String, category: Category?) {
        self.searchQuery = searchQuery
        self.category = category
    }

    func filterOutDupes(day: [Transaction]) -> [Transaction] {
        var seen = [Transaction]()
        let filtered = day.filter { entity -> Bool in
            if seen.contains(where: { $0.wrappedNote == entity.wrappedNote }) {
                return false
            } else {
                seen.append(entity)
                return true
            }
        }

        return filtered
    }
}

struct NumPadButton: ButtonStyle {
    public func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .scaleEffect(configuration.isPressed ? 1.22 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
            .brightness(configuration.isPressed ? 0.12 : 0)
            .opacity(configuration.isPressed ? 0.98 : 1)
    }
}

func getDollarOffset(big: CGFloat, small: CGFloat) -> CGFloat {
    let bigFont = UIFont.rounded(ofSize: big, weight: .regular)
    let smallFont = UIFont.rounded(ofSize: small, weight: .light)

    return bigFont.capHeight - smallFont.capHeight - 1
}

struct CategoryPickerView: View {
    @Binding var category: Category?
    @Binding var showPicker: Bool
    @Binding var showingCategoryView: Bool
    @Query private var categories: [Category]

    let initialCategory: Category?

    var darkMode: Bool

    var backgroundColor: Color {
        if darkMode {
            return Color("AlwaysDarkBackground")
        } else {
            return Color("AlwaysLightBackground")
        }
    }

    var secondaryBackgroundColor: Color {
        if darkMode {
            return Color("AlwaysDarkSecondaryBackground")
        } else {
            return Color("AlwaysLightSecondaryBackground")
        }
    }

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var heightOfScrollView: Double {
        let fontSize = UIFont.getBodyFontSize(dynamicTypeSize: dynamicTypeSize)

        let font = UIFont.rounded(ofSize: fontSize, weight: .semibold)

        if categories.count == 1 && initialCategory != nil {
            return font.lineHeight + 14.1
        }

        if initialCategory != nil {
            let height = Double(min(6, categories.count)) * (font.lineHeight + 14.1)
            let gap = Double(min(5, categories.count - 1)) * 8.0
            return height + gap
        } else {
            let height = Double(min(6, categories.count + 1)) * (font.lineHeight + 14.1)
            let gap = Double(min(5, categories.count)) * 8.0
            return height + gap
        }
    }

    var body: some View {
        //        VStack(alignment: .trailing, spacing: 8) {

        //            if categories.count > 1 || category == nil {
        HStack {
            Color.clear
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    showPicker = false
                }

            VStack(
                alignment: .trailing, spacing: (categories.count == 1 && initialCategory != nil) ? 0 : 8
            ) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("Edit")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .foregroundColor(darkMode ? Color("AlwaysLightBackground") : Color("AlwaysDarkBackground"))
                .background(
                    RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                        .fill(
                            darkMode
                            ? Color("AlwaysDarkSecondaryBackground") : Color("AlwaysLightSecondaryBackground"))
                )
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .onTapGesture {
                    Haptics.impact(.light)
                    showPicker = false
                    showingCategoryView = true
                }

                ScrollView(showsIndicators: false) {
                    ScrollViewReader { value in
                        VStack(alignment: .trailing, spacing: 8) {
                            ForEach(categories) { item in
                                if item != initialCategory {
                                    HStack(spacing: 7) {
                                        Text(item.wrappedEmoji)
                                            .font(.system(.footnote, design: .rounded))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                        //                                                    .font(.system(size: 14))
                                        Text(item.wrappedName)
                                            .font(.system(.body, design: .rounded).weight(.semibold))
                                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                        //                                                    .font(.system(size: 17.5, weight: .semibold, design: .rounded))
                                            .lineLimit(1)
                                    }
                                    .id(item.id)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .foregroundColor(
                                        darkMode ? Color("AlwaysLightBackground") : Color("AlwaysDarkBackground")
                                    )
                                    .background(
                                        item == category ? secondaryBackgroundColor : backgroundColor,
                                        in: RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                                    )
                                    .contentShape(Rectangle())
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                                            .strokeBorder(
                                                darkMode ? Color("AlwaysDarkOutline") : Color("AlwaysLightOutline"),
                                                style: StrokeStyle(lineWidth: 1.5))
                                    }
                                    .onTapGesture {
                                        if category == item {
                                            category = nil
                                        } else {
                                            category = item
                                        }

                                        showPicker = false
                                        //
                                    }
                                }
                            }
                        }
                        .onAppear {
                            if let last = categories.last {
                                if category == last && categories.count > 2 {
                                    value.scrollTo(categories[categories.count - 2].id)
                                } else {
                                    value.scrollTo(last.id)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: heightOfScrollView)
        //            }
    }

    init(
        category: Binding<Category?>?, showPicker: Binding<Bool>, showSheet: Binding<Bool>,
        income: Bool, darkMode: Bool
    ) {
        _categories = Query(
            filter: #Predicate<Category> { $0.income == income },
            sort: [SortDescriptor(\Category.order, order: .reverse)]
        )
        self.darkMode = darkMode
        initialCategory = category?.wrappedValue
        _category = category ?? Binding.constant(nil)
        _showPicker = showPicker
        _showingCategoryView = showSheet
    }
}

struct NoteView: View {
    @Binding var note: String
    @Binding var focused: Bool

    @FocusState private var textFocused: Bool
    let characterLimit = 50

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var noteWidth: CGFloat {
        let fontSize: CGFloat = UIFont.getBodyFontSize(dynamicTypeSize: dynamicTypeSize)
        //        let fontSize: CGFloat = fontSize
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        let roundedFont: UIFont
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            roundedFont = UIFont(descriptor: descriptor, size: fontSize)
        } else {
            roundedFont = systemFont
        }

        let attributes = [NSAttributedString.Key.font: roundedFont]

        let size = (note as NSString).size(withAttributes: attributes)

        let placeholder = String(localized: "Add Note")
        let placeholderSize = (placeholder as NSString).size(withAttributes: attributes)

        if !note.isEmpty {
            return size.width + 2
        } else {
            return placeholderSize.width
        }

        //        return max(size.width + 2, (placeholderSize.width + 1))
    }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "text.alignleft")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            //                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.SubtitleText)

            ZStack(alignment: .leading) {
                TextField("", text: $note)
                    .onReceive(Just(note)) { _ in limitText(characterLimit) }
                    .focused($textFocused)
                    .foregroundColor(Color.PrimaryText)

                if note.isEmpty {
                    Text("Add Note")
                        .foregroundColor(Color.SubtitleText)
                }
            }
            .font(.system(.body, design: .rounded).weight(.semibold))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            //            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .frame(width: min(noteWidth, UIScreen.main.bounds.width / 1.5), alignment: .center)
        }
        .onTapGesture {
            textFocused = true
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 11.5, style: .continuous)
                .stroke(Color.Outline, lineWidth: 1.5)
        )
        .onChange(of: textFocused) { _, newValue in
            focused = newValue
        }
    }

    func limitText(_ upper: Int) {
        if note.count > upper {
            note = String(note.prefix(upper))
        }
    }
}

struct RecurringPickerView: View {
    @Namespace var animation
    @Binding var repeatType: Int
    @Binding var repeatCoefficient: Int
    @Binding var showMenu: Bool

    @Binding var showPicker: Bool

    let stringArray = ["none", "daily", "weekly", "monthly"]
    let stringArray2 = ["", "days", "weeks", "months"]

    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
    var bottomEdge: Double = 15

    @State private var offset: CGFloat = 0

    @State var holdingType = 0
    @State var holdingCoefficient = 0

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
    var colourScheme: Int = 0

    @Environment(\.colorScheme) var systemColorScheme

    var darkMode: Bool {
        (colourScheme == 0 && systemColorScheme == .dark) || colourScheme == 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(stringArray, id: \.self) { string in
                HStack {
                    Text(LocalizedStringKey(string))
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .lineLimit(1)
                    Spacer()

                    if repeatType == (stringArray.firstIndex(of: string) ?? 0) && repeatCoefficient == 1 {
                        Image(systemName: "checkmark")
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        //                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                //                .font(.system(size: 18, weight: .medium, design: .rounded))
                .padding(6)
                .background {
                    if repeatType == (stringArray.firstIndex(of: string) ?? 0) && repeatCoefficient == 1 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                darkMode
                                ? Color("AlwaysDarkSecondaryBackground") : Color("AlwaysLightSecondaryBackground")
                            )
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if repeatType == (stringArray.firstIndex(of: string) ?? 0) && repeatCoefficient == 1 {
                        showMenu = false
                    } else {
                        withAnimation(.easeIn(duration: 0.15)) {
                            repeatType = (stringArray.firstIndex(of: string) ?? 0)
                            repeatCoefficient = 1
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showMenu = false
                        }
                    }
                }
            }

            HStack {
                if repeatCoefficient == 1 {
                    Text("custom")
                } else {
                    if repeatType == 1 {
                        Text(String(repeatCoefficient) + " " + String(localized: "\(repeatCoefficient) days"))
                    } else if repeatType == 2 {
                        Text(String(repeatCoefficient) + " " + String(localized: "\(repeatCoefficient) weeks"))
                    } else if repeatType == 3 {
                        Text(String(repeatCoefficient) + " " + String(localized: "\(repeatCoefficient) months"))
                    }
                }

                Spacer()

                if repeatCoefficient > 1 {
                    Image(systemName: "checkmark")
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    //                        .font(.system(size: 14, weight: .medium))
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.system(.title3, design: .rounded).weight(.medium))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            //            .font(.system(size: 18, weight: .medium, design: .rounded))
            .padding(6)
            .background {
                if repeatCoefficient > 1 {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            darkMode
                            ? Color("AlwaysDarkSecondaryBackground") : Color("AlwaysLightSecondaryBackground")
                        )
                        .matchedGeometryEffect(id: "TAB", in: animation)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if repeatCoefficient == 1 {
                    repeatCoefficient = 2
                    repeatType = 2

                    holdingType = repeatType
                    holdingCoefficient = repeatCoefficient
                }

                withAnimation {
                    showPicker = true
                }
            }
            .onChange(of: showPicker) { _, newValue in
                // holdingType != repeatType || holdingCoefficient != repeatCoefficient
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showMenu = false
                    }
                }
            }
        }
        .foregroundColor(darkMode ? Color("AlwaysLightBackground") : Color("AlwaysDarkBackground"))
        .padding(5)
        .frame(width: 188)
        .background(
            RoundedRectangle(cornerRadius: 11).fill(
                darkMode ? Color("AlwaysDarkBackground") : Color("AlwaysLightBackground")
            ).shadow(color: darkMode ? Color.clear : Color.gray.opacity(0.25), radius: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11).stroke(
                darkMode ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3))
    }
}

struct CustomRecurringView: View {
    @Binding var repeatType: Int
    @Binding var repeatCoefficient: Int
    @Binding var showPicker: Bool

    @Environment(\.colorScheme) var systemColorScheme
    var stringArray: [String] {
        return [
            "", "\(holdingCoefficient) days", "\(holdingCoefficient) weeks",
            "\(holdingCoefficient) months"
        ]
    }

    @Environment(\.dismiss) var dismiss

    @State var holdingType = 0
    @State var holdingCoefficient = 0

    var body: some View {
        VStack(spacing: 35) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    //                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.SubtitleText)
                        .padding(7)
                        .background(Color.SecondaryBackground, in: Circle())
                        .contentShape(Circle())
                }

                Spacer()

                Text("Custom Interval")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                //                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                Spacer()

                Button {
                    repeatType = holdingType
                    repeatCoefficient = holdingCoefficient

                    Haptics.impact(.light)

                    dismiss()

                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    //                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.IncomeGreen)
                        .padding(7)
                        .background(Color.IncomeGreen.opacity(0.23), in: Circle())
                        .contentShape(Circle())
                }
            }

            HStack(spacing: 10) {
                Text("Repeats every")
                    .font(.system(size: 23, weight: .medium, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
                    .padding(.trailing, 3)

                VStack {
                    Button {
                        holdingCoefficient += 1
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(7)
                            .background(
                                Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                            .contentShape(Circle())
                            .opacity(holdingCoefficient == 30 ? 0.25 : 1)
                    }
                    .disabled(holdingCoefficient == 30)

                    Text("\(holdingCoefficient)")
                        .font(.system(size: 23, weight: .medium, design: .rounded))
                        .padding(7)
                        .background {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.SecondaryBackground)
                                .frame(width: 40, height: 40)
                        }

                    Button {
                        holdingCoefficient -= 1
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(7)
                            .background(
                                Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                            .contentShape(Circle())
                            .opacity(holdingCoefficient == 2 ? 0.25 : 1)
                    }
                    .disabled(holdingCoefficient == 2)
                }

                VStack {
                    Button {
                        holdingType -= 1
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(7)
                            .background(
                                Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                            .contentShape(Circle())
                            .opacity(holdingType == 1 ? 0.25 : 1)
                    }
                    .disabled(holdingType == 1)

                    Group {
                        if holdingType == 1 {
                            Text("\(holdingCoefficient) days")
                        } else if holdingType == 2 {
                            Text("\(holdingCoefficient) weeks")
                        } else if holdingType == 3 {
                            Text("\(holdingCoefficient) months")
                        }
                    }
                    .font(.system(size: 23, weight: .medium, design: .rounded))
                    .padding(7)
                    .background {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.SecondaryBackground)
                            .frame(height: 40)
                    }

                    Button {
                        holdingType += 1
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding(7)
                            .background(
                                Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                            .contentShape(Circle())
                            .opacity(holdingType == 3 ? 0.25 : 1)
                    }
                    .disabled(holdingType == 3)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(13)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            holdingType = repeatType
            holdingCoefficient = repeatCoefficient
        }
    }
}

struct ButtonView: View {
    let number: Int
    let size: CGSize

    var body: some View {
        Text("\(number)")
            .font(.system(size: 34, weight: .regular, design: .rounded))
            .frame(width: size.width * 0.3, height: size.height * 0.22)
            .background(Color.SecondaryBackground)
            .foregroundColor(Color.PrimaryText)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
#Preview {
    let dataController = DataController.shared

    TransactionView(toEdit: nil)
        .modelContainer(dataController.modelContainer)
        .environmentObject(dataController)
}


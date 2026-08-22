import SwiftUI

/// A two-drum time picker (hours + minutes) backed by a single UIPickerView.
/// Uses two components to avoid SwiftUI gesture conflicts that occur with
/// two separate UIPickerView instances side-by-side.
struct TimeDrumPicker: UIViewRepresentable {
    @Binding var hour: Int
    @Binding var minute: Int

    private let hours: [Int] = Array(0...23)
    private let minutes: [Int] = Array(stride(from: 0, through: 55, by: 5))

    private static let rowHeight: CGFloat = 40

    func makeCoordinator() -> Coordinator {
        Coordinator(hour: $hour, minute: $minute)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.backgroundColor = .clear

        if let hIdx = hours.firstIndex(of: hour) {
            picker.selectRow(hIdx, inComponent: 0, animated: false)
        }
        if let mIdx = minutes.firstIndex(of: minute) {
            picker.selectRow(mIdx, inComponent: 1, animated: false)
        }

        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        context.coordinator.hourBinding = $hour
        context.coordinator.minuteBinding = $minute
        context.coordinator.currentHour = hour
        context.coordinator.currentMinute = minute

        if let hIdx = hours.firstIndex(of: hour), uiView.selectedRow(inComponent: 0) != hIdx {
            uiView.selectRow(hIdx, inComponent: 0, animated: true)
        }
        if let mIdx = minutes.firstIndex(of: minute), uiView.selectedRow(inComponent: 1) != mIdx {
            uiView.selectRow(mIdx, inComponent: 1, animated: true)
        }

        uiView.reloadAllComponents()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var hourBinding: Binding<Int>
        var minuteBinding: Binding<Int>
        var currentHour: Int
        var currentMinute: Int

        init(hour: Binding<Int>, minute: Binding<Int>) {
            self.hourBinding = hour
            self.minuteBinding = minute
            self.currentHour = hour.wrappedValue
            self.currentMinute = minute.wrappedValue
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0: return 24  // hours 0-23
            case 1: return 12  // minutes 0,5,10...55
            default: return 0
            }
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            Self.rowHeight
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            switch component {
            case 0: return 96
            case 1: return 96
            default: return 0
            }
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let container = view as? TimeDrumRowView ?? TimeDrumRowView()
            let isSelected: Bool
            let text: String

            switch component {
            case 0:
                let value = row
                text = String(format: "%02d", value)
                isSelected = value == currentHour
            case 1:
                let value = row * 5
                text = String(format: "%02d", value)
                isSelected = value == currentMinute
            default:
                text = ""
                isSelected = false
            }

            container.configure(text: text, isSelected: isSelected)
            return container
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            switch component {
            case 0: return String(format: "%02d", row)
            case 1: return String(format: "%02d", row * 5)
            default: return nil
            }
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            switch component {
            case 0:
                let newHour = row
                currentHour = newHour
                hourBinding.wrappedValue = newHour
            case 1:
                let newMinute = row * 5
                currentMinute = newMinute
                minuteBinding.wrappedValue = newMinute
            default:
                break
            }
        }

        static var rowHeight: CGFloat { 40 }
    }
}

// MARK: - Private Row View

private final class TimeDrumRowView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }

    func configure(text: String, isSelected: Bool) {
        label.text = text
        label.font = .monospacedSystemFont(ofSize: 22, weight: isSelected ? .bold : .regular)
        label.textColor = isSelected ? .label : .secondaryLabel
    }
}

# Packet Accessor Reference

This document provides a comprehensive reference for accessing VRT packet data. The library provides two parallel APIs:

- **Compile-Time API**: `DataPacket<>`, `ContextPacket<>` - For transmit side where structure is known at compile time
- **Runtime API**: `DataPacketView`, `ContextPacketView` - For receive side with automatic validation

## Important Terminology

- **Packet Components**: The structural elements of a VRT packet:
  - **Header**: The first 32-bit word containing packet type, counts, and indicator bits
  - **Stream ID**: Optional 32-bit stream identifier (position after header)
  - **Class ID**: Optional 64-bit class identifier
  - **Timestamp**: Optional timestamp (integer and/or fractional parts)
  - **Payload/Context**: Data payload (data packets) or CIF-encoded fields (context packets)
  - **Trailer**: Optional 32-bit trailer word (data packets only)

- **Context Fields**: CIF-encoded fields specific to context packets, accessed via `operator[]` returning `FieldProxy`
  - These are NOT packet components but encoded values within the context section
  - Only available in `ContextPacket` and `ContextPacketView`
  - Examples: bandwidth, reference_level, gain, etc.

## Quick Comparison

| Feature | DataPacket<...> | DataPacketView | ContextPacket<...> | ContextPacketView |
|---------|----------------|----------------|-------------------|-------------------|
| **Use Case** | Transmit (known structure) | Receive (unknown structure) | Transmit (known structure) | Receive (unknown structure) |
| **Validation** | Manual (call `validate()`) | Automatic on construction | Manual (call `validate()`) | Automatic on construction |
| **Return Types** | Raw values | `std::optional<T>` | Raw values | `std::optional<T>` |
| **Field Access** | Direct getters/setters | Optional getters | `operator[]` → FieldProxy | `operator[]` → FieldProxy |
| **Mutability** | Mutable | Read-only | Mutable | Read-only |
| **Stream ID** | Compile-time optional | Runtime detected | Always present | Always present |
| **Trailer** | Compile-time optional | Runtime detected | Never (spec) | Never (spec) |

---

## Packet-Level Methods

### Size and Validation

| Method/Member | DataPacket | DataPacketView | ContextPacket | ContextPacketView |
|--------------|-----------|----------------|---------------|-------------------|
| `packet_size_words()` | ✓ returns `uint16_t` | ✓ returns `size_t` | ✗ | ✓ returns `size_t` |
| `packet_size_bytes()` | ✗ | ✓ returns `size_t` | ✗ | ✓ returns `size_t` |
| `size_words` (static) | ✗ (has `total_words`) | N/A | ✓ constexpr `size_t` | N/A |
| `size_bytes` (static) | ✓ constexpr `size_t` | N/A | ✓ constexpr `size_t` | N/A |
| `validate(size_t)` | ✓ returns `ValidationError` | ✗ (auto-validated) | ✓ returns `ValidationError` | ✗ (auto-validated) |
| `error()` | ✗ | ✓ returns `ValidationError` | ✗ | ✓ returns `ValidationError` |
| `is_valid()` | ✗ | ✓ returns `bool` | ✗ | ✓ returns `bool` |
| `type()` | ✗ (template parameter) | ✓ returns `PacketType` | ✗ (template parameter) | ✗ |

**Note**: Compile-time packets (DataPacket, ContextPacket) expose static constexpr size members, while runtime views provide instance methods that read from the packet buffer.

### Packet Count

| Method | DataPacket | DataPacketView | ContextPacket | ContextPacketView |
|--------|-----------|----------------|---------------|-------------------|
| `packet_count()` | ✓ returns `uint8_t` | ✓ returns `uint8_t` | ✗ | ✗ |
| `set_packet_count(uint8_t)` | ✓ | ✗ | ✗ | ✗ |

**Note**: Packet count is a 4-bit header field (valid range 0-15) only available in data packets. Context packets do not expose packet count accessors. Values > 15 are truncated with debug warnings.

---

## Packet Component Presence Queries

### Compile-Time Packets (DataPacket, ContextPacket)

These use compile-time `static constexpr bool` members determined by template parameters:
- `has_stream_id`
- `has_class_id`
- `has_timestamp`
- `has_trailer` (DataPacket only; always false for ContextPacket per spec)

### Runtime Views (DataPacketView, ContextPacketView)

| Method | DataPacketView | ContextPacketView | Notes |
|--------|----------------|-------------------|-------|
| `has_stream_id()` | ✓ returns `bool` | ✗ | Presence check (DataPacket only) |
| `has_class_id()` | ✓ returns `bool` | ✗ | Presence check from header bit 27 |
| `has_trailer()` | ✓ returns `bool` | ✗ | From header bit 26 |
| `has_timestamp_integer()` | ✓ returns `bool` | ✗ | TSI ≠ none |
| `has_timestamp_fractional()` | ✓ returns `bool` | ✗ | TSF ≠ none |
| `tsi()` | ✓ returns `TsiType` | ✗ | Timestamp integer type |
| `tsf()` | ✓ returns `TsfType` | ✗ | Timestamp fractional type |

**Note**: ContextPacketView does not provide presence query methods. Stream ID presence is checked via the optional return from `stream_id()`. Class ID presence must be inferred from the optional return of `class_id()`.

---

## Packet Component Accessors

These methods access the optional packet components that appear between the header and payload/context section.

### Stream ID

| Method | DataPacket | DataPacketView | ContextPacket | ContextPacketView |
|--------|-----------|----------------|---------------|-------------------|
| `stream_id()` | ✓ `uint32_t` (if `has_stream_id`) | ✓ `optional<uint32_t>` | ✓ `uint32_t` (always) | ✓ `optional<uint32_t>` |
| `set_stream_id(uint32_t)` | ✓ (if `has_stream_id`) | ✗ | ✓ (always) | ✗ |

**Note**: Context packets always include Stream ID per VITA 49.2 spec.

### Class ID

| Method | DataPacket | DataPacketView | ContextPacket | ContextPacketView |
|--------|-----------|----------------|---------------|-------------------|
| `class_id()` | ✓ `ClassIdValue` (if `has_class_id`) | ✓ `optional<ClassIdValue>` | ✓ `ClassIdValue` (if `has_class_id`) | ✓ `optional<ClassIdValue>` |
| `set_class_id(ClassIdValue)` | ✓ (if `has_class_id`) | ✗ | ✓ (if `has_class_id`) | ✗ |

**Note**: Uses `[[nodiscard]]` attribute to prevent ignoring validation failures.

### Timestamp

**Compile-Time Packets** (`DataPacket`, `ContextPacket`):

| Method | Return Type | Availability |
|--------|-------------|--------------|
| `timestamp()` | `TimeStampType` | When `HasTimestamp<TimeStampType>` |
| `set_timestamp(TimeStampType)` | void | When `HasTimestamp<TimeStampType>` |

**Runtime Views**:

| Method | DataPacketView | ContextPacketView |
|--------|----------------|-------------------|
| `timestamp_integer()` | ✓ `optional<uint32_t>` | ✗ |
| `timestamp_fractional()` | ✓ `optional<uint64_t>` | ✗ |

**Important API Gap**: `ContextPacketView` does not provide any timestamp accessor methods, even though timestamp components may be present in the packet structure. This means timestamps in context packets are currently inaccessible via the runtime API. Context Fields accessed via `operator[]` are CIF-encoded fields within the context section, not timestamp packet components.

### Trailer

| Method | DataPacket | DataPacketView | ContextPacket | ContextPacketView |
|--------|-----------|----------------|---------------|-------------------|
| `trailer()` | ✓ `TrailerView` (if `HasTrailer`) | ✓ `optional<uint32_t>` (raw word) | ✗ (spec forbids) | ✗ (spec forbids) |
| `trailer() const` | ✓ `ConstTrailerView` (if `HasTrailer`) | — | ✗ | ✗ |

**Note**: Context packets never include trailers per VITA 49.2 specification (bit 26 is reserved and must be zero).

For trailer bit manipulation, see [TrailerView API](#trailerview-api-data-packets) below.

---

## Buffer and Payload Access

### Data Packets

| Method | DataPacket | DataPacketView |
|--------|-----------|----------------|
| `payload()` | ✓ `span<uint8_t, N>` | ✓ `span<const uint8_t>` |
| `payload() const` | ✓ `span<const uint8_t, N>` | — |
| `set_payload(const uint8_t*, size_t)` | ✓ | ✗ |
| `payload_size_bytes()` | ✓ (static constexpr) | ✓ returns `size_t` |
| `payload_size_words()` | ✓ (static constexpr) | ✓ returns `size_t` |
| `as_bytes()` | ✓ `span<uint8_t, N>` | ✓ `span<const uint8_t>` |
| `as_bytes() const` | ✓ `span<const uint8_t, N>` | — |
| `buffer_size()` | ✗ (use `size_bytes`) | ✓ returns `size_t` |

**Note**: Compile-time packets use fixed-size spans with compile-time extent; runtime views use dynamic spans.

### Context Packets

Context packets don't have a traditional "payload" - instead they use CIF-based Context Field access:

| Method | ContextPacket | ContextPacketView | Purpose |
|--------|---------------|-------------------|---------|
| `operator[](field_tag)` | ✓ mutable `FieldProxy` | ✓ const `FieldProxy` | Access Context Fields (CIF-encoded) |
| `as_bytes()` | ✓ `span<uint8_t, N>` | ✗ | Full packet buffer |
| `as_bytes() const` | ✓ `span<const uint8_t, N>` | ✗ | Full packet buffer (const) |
| `buffer_size()` | ✗ (use `size_bytes`) | ✓ returns `size_t` | Buffer size query |

**Internal helpers** (do not call directly; for FieldProxy use only):
- `context_buffer()` / `mutable_context_buffer()` - Raw buffer pointers
- `context_base_offset()` - Offset to context field area

---

## CIF Metadata (Context Packets Only)

### Compile-Time (ContextPacket)

Static constexpr members publishing CIF masks for builders and tests:

| Member | Type | Description |
|--------|------|-------------|
| `cif0_value` | `uint32_t` | CIF0 with automatic enable bits |
| `cif1_value` | `uint32_t` | CIF1 mask |
| `cif2_value` | `uint32_t` | CIF2 mask |
| `cif3_value` | `uint32_t` | CIF3 mask |

Also available via methods:
- `static constexpr uint32_t cif0()`
- `static constexpr uint32_t cif1()`
- `static constexpr uint32_t cif2()`
- `static constexpr uint32_t cif3()`

### Runtime (ContextPacketView)

| Method | Return Type | Description |
|--------|-------------|-------------|
| `cif0()` | `uint32_t` | Parsed CIF0 word (diagnostic) |
| `cif1()` | `uint32_t` | Parsed CIF1 word (diagnostic) |
| `cif2()` | `uint32_t` | Parsed CIF2 word (diagnostic) |
| `cif3()` | `uint32_t` | Parsed CIF3 word (diagnostic) |

---

## Context Field Access (Context Packets Only)

Both compile-time (`ContextPacket<>`) and runtime (`ContextPacketView`) context packets use `operator[]` to access CIF-encoded fields within the context section of the packet (NOT packet components like stream_id or timestamp). This returns a `FieldProxy` object providing a three-tier access pattern:

```cpp
auto proxy = packet[field::bandwidth];
```

### FieldProxy Methods

| Method | Compile-Time (mutable) | Runtime (const) | Description |
|--------|----------------------|-----------------|-------------|
| `raw_bytes()` | ✓ read | ✓ read | Literal on-wire bytes |
| `set_raw_bytes(span)` | ✓ write | ✗ | Set on-wire bytes in bulk |
| `raw_value()` | ✓ read | ✓ read | Structured format (e.g., Q52.12 as `uint64_t`) |
| `set_raw_value(T)` | ✓ write | ✗ | Set structured value |
| `value()` | ✓ read | ✓ read | Interpreted units (Hz, dBm, etc.) if defined |
| `set_value(T)` | ✓ write | ✗ | Set interpreted value |
| `operator bool()` | ✓ | ✓ | Check field presence |

**Notes**:
- Variable-length fields include the count word automatically in `raw_bytes()`
- `value()` methods only available if `FieldTraits` specialization defines interpreted conversions
- FieldProxy caches offset, size, and presence on creation for efficiency

**Example Usage**:
```cpp
// Access Context Fields (not packet components like stream_id or timestamp)
// Context Fields are CIF-encoded fields within the context section

// Presence check
if (packet[field::bandwidth]) {  // bandwidth is a Context Field
    // Read interpreted value (Hz)
    double bw = packet[field::bandwidth].value();

    // Read raw structured value (Q52.12 as uint64_t)
    uint64_t raw = packet[field::bandwidth].raw_value();

    // Read raw bytes
    auto bytes = packet[field::bandwidth].raw_bytes();
}

// Set value (compile-time packets only)
packet[field::bandwidth].set_value(20e6); // 20 MHz

// Note: Packet components like stream_id use direct accessors, not operator[]
// packet.stream_id();  // Correct for packet component accessor
// packet[field::stream_id];  // Wrong - stream_id is not a Context Field
```

---

## TrailerView API (Data Packets)

When `DataPacket<>` has `HasTrailer == Trailer::included`, the `trailer()` method returns a view object for bit manipulation.

### ConstTrailerView (Read-Only)

| Method | Return Type | Description |
|--------|-------------|-------------|
| `raw()` | `uint32_t` | Entire trailer word |
| `valid_data()` | `bool` | Valid data indicator |
| `reference_point()` | `bool` | Reference point indicator |
| `calibrated_time()` | `bool` | Calibrated time indicator |
| `sample_loss()` | `bool` | Sample loss indicator |
| `over_range()` | `bool` | Over-range indicator |
| `spectral_inversion()` | `bool` | Spectral inversion indicator |
| `detected_signal()` | `bool` | Detected signal indicator |
| `agc_mgc()` | `bool` | AGC/MGC indicator |
| `reference_lock()` | `bool` | Reference lock indicator |
| `context_packets()` | `uint8_t` | Associated context packet count (7 bits) |

### TrailerView (Mutable)

Inherits all methods from `ConstTrailerView` and adds:

| Method | Parameters | Description |
|--------|-----------|-------------|
| `set_raw(uint32_t)` | value | Set entire trailer word |
| `clear()` | — | Zero entire trailer word |
| `set_valid_data(bool)` | state | Set valid data bit |
| `set_reference_point(bool)` | state | Set reference point bit |
| `set_calibrated_time(bool)` | state | Set calibrated time bit |
| `set_sample_loss(bool)` | state | Set sample loss bit |
| `set_over_range(bool)` | state | Set over-range bit |
| `set_spectral_inversion(bool)` | state | Set spectral inversion bit |
| `set_detected_signal(bool)` | state | Set detected signal bit |
| `set_agc_mgc(bool)` | state | Set AGC/MGC bit |
| `set_reference_lock(bool)` | state | Set reference lock bit |
| `set_context_packets(uint8_t)` | count | Set context packet count (0-127) |

---

## Return Types and Attributes

### Compile-Time Packets
- Return plain values: `uint32_t`, `ClassIdValue`, `span<uint8_t, N>`
- No optionals - template enforces field presence at compile time
- Methods use `requires` clauses to conditionally compile based on template parameters

### Runtime Views
- Return `std::optional<T>` for any field that could be missing or invalid
- Even "mandatory" fields use optionals to prevent accessing unvalidated memory
- Many methods marked `[[nodiscard]]` to discourage ignoring validation failures

---

## Implementation Reference

For implementation details and exact signatures, see:

### Data Packets (Compile-Time)
- **File**: `include/vrtio/detail/data_packet.hpp`
- **Class**: `DataPacket<PacketType Type, ClassIdType ClassId, TimeStampType TimeStamp, Trailer HasTrailer, size_t PayloadWords>`
- **Key sections**:
  - Header accessors (packet_count, packet_size_words)
  - Stream ID (conditional on has_stream_id)
  - Class ID (conditional on has_class_id)
  - Timestamp (conditional on HasTimestamp)
  - Trailer view (conditional on HasTrailer)
  - Payload access (fixed-size spans)
  - Validation method

### Data Packets (Runtime)
- **File**: `include/vrtio/detail/data_packet_view.hpp`
- **Class**: `DataPacketView`
- **Key sections**:
  - Automatic validation on construction
  - Validation query methods (error, is_valid)
  - Type and presence queries (type, has_*, tsi, tsf)
  - Optional field accessors (stream_id, class_id, timestamp_*, trailer)
  - Payload and size queries (dynamic spans)

### Context Packets (Compile-Time)
- **File**: `include/vrtio/detail/context_packet.hpp`
- **Class**: `ContextPacketBase<...>` (aliased as `ContextPacket<...>`)
- **Key sections**:
  - Stream ID (always present)
  - Class ID (conditional on has_class_id)
  - Timestamp (conditional on has_timestamp)
  - FieldProxy access via operator[]
  - CIF static constexpr members
  - Validation method

### Context Packets (Runtime)
- **File**: `include/vrtio/detail/context_packet_view.hpp`
- **Class**: `ContextPacketView`
- **Key sections**:
  - Automatic validation on construction
  - Validation query methods
  - Optional accessors (stream_id, class_id)
  - CIF query methods (cif0-3)
  - FieldProxy access via operator[]
  - Size queries

### Trailer Views
- **File**: `include/vrtio/detail/trailer_view.hpp`
- **Classes**: `ConstTrailerView`, `TrailerView`
- **Coverage**: All VITA 49.2 defined trailer bits

### Field Proxy
- **File**: `include/vrtio/detail/field_proxy.hpp`
- **Template**: `FieldProxy<FieldTag, PacketType>`
- **Methods**: raw_bytes, raw_value, value (with corresponding setters for mutable packets)

---

## Notes

- `ContextPacket<...>` is a direct alias over `ContextPacketBase`; all accessors are inherited unchanged
- Runtime views default to `std::optional` to guard against malformed packets
- Context packet CIF access is exclusively routed through field tags and `FieldProxy`
- Direct buffer pointers in context packets are marked as implementation details and should remain internal
- The `[[nodiscard]]` attribute mirrors guidance in `docs/style.md` to prevent ignoring validation problems
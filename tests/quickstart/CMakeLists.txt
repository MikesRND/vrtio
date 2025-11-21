# Quickstart tests - executable documentation snippets

# Create Data Packet snippet test
vrtio_add_gtest(quickstart_data_packet data_packet_test.cpp)

# Create Context Packet snippet test
vrtio_add_gtest(quickstart_context_packet context_packet_test.cpp)

# Read VRT File snippet test
vrtio_add_gtest(quickstart_file_reader file_reader_test.cpp TEST_DATA_DIR "${CMAKE_SOURCE_DIR}/tests/data")

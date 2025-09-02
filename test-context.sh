#!/bin/bash
# Test script for context display features

echo "Testing Context Display Options..."
echo "================================="

# Test 1: Show only usable percentage (default)
echo -e "\nTest 1: Default (SHOW_CONTEXT_PERCENTAGE_USABLE=true):"
echo '{"transcript_path":"/tmp/test-transcript.jsonl","model":{"display_name":"Opus 4.1"},"session_id":"test1","cwd":"'$(pwd)'","cost":{"total_cost_usd":0}}' | ./cc-cleanline.sh

# Test 2: Show absolute length
echo -e "\nTest 2: Absolute length (SHOW_CONTEXT_LENGTH=true):"
echo '{"transcript_path":"/tmp/test-transcript.jsonl","model":{"display_name":"Opus 4.1"},"session_id":"test2","cwd":"'$(pwd)'","cost":{"total_cost_usd":0}}' | \
SHOW_CONTEXT_LENGTH=true SHOW_CONTEXT_PERCENTAGE_USABLE=false ./cc-cleanline.sh

# Test 3: Show percentage of 200k
echo -e "\nTest 3: Percentage of 200k (SHOW_CONTEXT_PERCENTAGE=true):"
echo '{"transcript_path":"/tmp/test-transcript.jsonl","model":{"display_name":"Opus 4.1"},"session_id":"test3","cwd":"'$(pwd)'","cost":{"total_cost_usd":0}}' | \
SHOW_CONTEXT_PERCENTAGE=true SHOW_CONTEXT_PERCENTAGE_USABLE=false ./cc-cleanline.sh

# Test 4: Show both percentages
echo -e "\nTest 4: Both percentages:"
echo '{"transcript_path":"/tmp/test-transcript.jsonl","model":{"display_name":"Opus 4.1"},"session_id":"test4","cwd":"'$(pwd)'","cost":{"total_cost_usd":0}}' | \
SHOW_CONTEXT_PERCENTAGE=true SHOW_CONTEXT_PERCENTAGE_USABLE=true ./cc-cleanline.sh

# Test 5: Show all three metrics
echo -e "\nTest 5: All three metrics:"
echo '{"transcript_path":"/tmp/test-transcript.jsonl","model":{"display_name":"Opus 4.1"},"session_id":"test5","cwd":"'$(pwd)'","cost":{"total_cost_usd":0}}' | \
SHOW_CONTEXT_LENGTH=true SHOW_CONTEXT_PERCENTAGE=true SHOW_CONTEXT_PERCENTAGE_USABLE=true ./cc-cleanline.sh

# Test 6: No context display
echo -e "\nTest 6: No context display:"
echo '{"transcript_path":"/tmp/test-transcript.jsonl","model":{"display_name":"Opus 4.1"},"session_id":"test6","cwd":"'$(pwd)'","cost":{"total_cost_usd":0}}' | \
SHOW_CONTEXT_LENGTH=false SHOW_CONTEXT_PERCENTAGE=false SHOW_CONTEXT_PERCENTAGE_USABLE=false ./cc-cleanline.sh

echo -e "\n================================="
echo "Test complete!"
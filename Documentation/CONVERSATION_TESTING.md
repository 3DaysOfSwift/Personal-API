# Conversation acceptance checks

Run PersonalAPI from Xcode on the existing iPhone Air simulator with ⌘R. Do not uninstall or erase its data.

1. Ask “Who was Andrew Goodall?” and then “Where did I meet him?” Both exchanges should remain visible. Check that the second answer concerns the same person and contains only recorded facts.
2. Ask a question about feelings you have not recorded. Expect an honest gap, not an invented emotion.
3. Tap Log a memory about this. Write your own answer, save, tap Done, then Answer again. The latest answer should use the new entry without duplicating the question.
4. Use the top-left conversation menu to start a New chat. Reopen the previous chat from Saved chats; relaunch and check its messages remain.
5. Mark an answer Not helpful, select a reason and write a correction. Reopen the chat; feedback should remain. It must not appear in Training as a journal entry.
6. Send a question, press Stop, then Answer again. Ensure no duplicate or late response appears.
7. Export chats from the menu. Inspect the JSON. Delete a chat from Saved chats and confirm journal entries remain in Training.
8. Check the raised composer with the keyboard shown/hidden, larger text sizes, and the top-right tab toggle.

Automated checks cover persistence, failure retention, cancellation, question-only context, context bounds, fresh evidence on retry, and journal preservation on chat deletion. Live model relevance, inference quality and this iPhone UI flow still require manual verification.

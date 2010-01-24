open:
	cil summary --is-open

next-milestone:
	cil summary --is-open --label=Milestone-v0.07

closed:
	cil summary --is-closed

clean:
	find . -name '*~' -exec rm {} ';'

.PHONY: issue-summary issue-list clean

issue-summary:
	cil summary --is-open --label=Milestone-v0.06

issue-list:
	cil list --is-open --label=Milestone-v0.06

clean:
	find . -name '*~' -exec rm {} ';'

.PHONY: issue-summary issue-list clean

defmodule RaffleyWeb.RuleHTML do
  use RaffleyWeb, :html

  embed_templates "rule_html/*"

  def show(assigns) do
    ~H"""
    <div class="rules">
      <h1>dont forget</h1>
      <p>
        {@rule.text}
      </p>
    </div>
    """
  end
end

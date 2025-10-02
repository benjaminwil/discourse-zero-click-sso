# frozen_string_literal: true

ZeroClickSso::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::ZeroClickSso::Engine, at: "zero-click-sso" }

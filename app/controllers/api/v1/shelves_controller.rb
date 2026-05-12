module Api
  module V1
    class ShelvesController < BaseController
      before_action :authenticate_user!

      def index
        authorize Shelf
        shelves = Shelf.active.order(name: :asc)
        result = shelves.map do |shelf|
          shelf.attributes.merge(
            current_usage: shelf.current_usage,
            usage_rate: shelf.usage_rate
          )
        end
        render_json(result)
      end

      def show
        authorize Shelf
        shelf = Shelf.find(params[:id])
        result = shelf.attributes.merge(
          current_usage: shelf.current_usage,
          usage_rate: shelf.usage_rate
        )
        render_json(result)
      end

      def create
        authorize Shelf, :manage?
        shelf = Shelf.new(shelf_params)
        shelf.created_by = current_user.id
        shelf.updated_by = current_user.id

        if shelf.save
          render_json(shelf, status: :created)
        else
          render_error(shelf.errors.full_messages.join(", "))
        end
      end

      def update
        authorize Shelf, :manage?
        shelf = Shelf.find(params[:id])
        shelf.updated_by = current_user.id

        if shelf.update(shelf_params)
          render_json(shelf)
        else
          render_error(shelf.errors.full_messages.join(", "))
        end
      end

      def destroy
        authorize Shelf, :manage?
        shelf = Shelf.find(params[:id])

        if Package.exists?(shelf_id: shelf.id)
          return render_error("该货架上存在包裹，无法删除")
        end

        shelf.destroy
        render_json({ message: "删除成功" })
      end

      def toggle_status
        authorize Shelf, :manage?
        shelf = Shelf.find(params[:id])
        shelf.status = shelf.enabled? ? :disabled : :enabled
        shelf.updated_by = current_user.id
        shelf.save!
        render_json(shelf)
      end

      private

      def shelf_params
        params.require(:shelf).permit(:name, :location, :capacity, :description)
      end
    end
  end
end
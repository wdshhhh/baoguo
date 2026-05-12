module Api
  module V1
    class CourierCompaniesController < BaseController
      before_action :authenticate_user!

      def index
        authorize CourierCompany
        companies = CourierCompany.active.order(name: :asc)
        render_json(companies)
      end

      def show
        authorize CourierCompany
        company = CourierCompany.find(params[:id])
        render_json(company)
      end

      def create
        authorize CourierCompany, :manage?
        company = CourierCompany.new(company_params)
        company.created_by = current_user.id
        company.updated_by = current_user.id

        if company.save
          render_json(company, status: :created)
        else
          render_error(company.errors.full_messages.join(", "))
        end
      end

      def update
        authorize CourierCompany, :manage?
        company = CourierCompany.find(params[:id])
        company.updated_by = current_user.id

        if company.update(company_params)
          render_json(company)
        else
          render_error(company.errors.full_messages.join(", "))
        end
      end

      def destroy
        authorize CourierCompany, :manage?
        company = CourierCompany.find(params[:id])

        if Package.exists?(courier_company: company.code)
          return render_error("该快递公司下存在包裹，无法删除")
        end

        company.destroy
        render_json({ message: "删除成功" })
      end

      def toggle_status
        authorize CourierCompany, :manage?
        company = CourierCompany.find(params[:id])
        company.status = company.enabled? ? :disabled : :enabled
        company.updated_by = current_user.id
        company.save!
        render_json(company)
      end

      private

      def company_params
        params.require(:courier_company).permit(:name, :code, :logo_url, :contact_phone, :website, :description)
      end
    end
  end
end